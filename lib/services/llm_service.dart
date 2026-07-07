import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'model_download_service.dart';

/// Abstract interface for LLM services.
abstract class LlmService {
  bool get isModelLoaded;
  Future<void> initialize();
  Stream<String> generateStream(String prompt);
  Future<String> generate(String prompt);
  void dispose();
}

/// On-device LLM using CodeGemma 2B via flutter_gemma / MediaPipe.
///
/// On first use the model file must be downloaded (~900 MB) via
/// [ModelDownloadService]. Until the model is ready this service
/// transparently falls back to [TemplateLlmService] so the app always works.
///
/// Usage:
///   final gemma = GemmaLlmService();
///   await gemma.initialize();
///   final answer = await gemma.generate('Arrays Medium');
class GemmaLlmService implements LlmService {
  static final GemmaLlmService _instance = GemmaLlmService._internal();
  factory GemmaLlmService() => _instance;
  GemmaLlmService._internal();

  bool _isLoaded = false;
  bool _attempted = false; // only try init once
  Future<void>? _initFuture; // serialise concurrent calls
  final _fallback = TemplateLlmService();

  /// Whether we have already consumed [FlutterGemmaPlugin.instance.isInitialized]
  /// in a previous init attempt. The plugin's internal completer is permanent
  /// (not reset between attempts), so awaiting it a second time replays the
  /// stored result — which may be a stale error even if native re-init succeeded.
  bool _isInitializedConsumed = false;

  @override
  bool get isModelLoaded => _isLoaded;

  @override
  Future<void> initialize() async {
    if (_isLoaded) return;
    // If a previous attempt already failed, go straight to fallback
    if (_attempted) {
      await _fallback.initialize();
      return;
    }
    // Serialise concurrent callers — only one native init ever runs
    _initFuture ??= _doInitialize();
    return _initFuture;
  }

  /// Clears the init state so the next [initialize] call retries the
  /// on-device Gemma model. Always call this before re-initializing after
  /// the model file has just been downloaded.
  void reset() {
    _isLoaded = false;
    _attempted = false;
    _initFuture = null;
    // Do NOT reset _isInitializedConsumed — the plugin's internal completer
    // is permanent, so we must keep skipping isInitialized on subsequent retries.
  }

  Future<void> _doInitialize() async {
    _attempted = true;

    // iOS Simulator has no Metal GPU — MediaPipe will JIT-crash the native
    // layer before Dart's try-catch can handle it. Skip native init entirely.
    if (Platform.isIOS &&
        Platform.environment.containsKey('SIMULATOR_DEVICE_NAME')) {
      await _fallback.initialize();
      return;
    }

    final downloader = ModelDownloadService();
    final isDownloaded = await downloader.isModelDownloaded();
    debugPrint('[GemmaLlmService] model downloaded: $isDownloaded');

    if (!isDownloaded) {
      await _fallback.initialize();
      return;
    }

    try {
      debugPrint(
          '[GemmaLlmService] calling FlutterGemmaPlugin.instance.init()');
      await FlutterGemmaPlugin.instance.init(
        maxTokens: 1024,
        temperature: 0.8,
        randomSeed: 1,
        topK: 40,
      );
      debugPrint(
          '[GemmaLlmService] init() returned — checking initialization state');

      // The plugin stores init success/failure in an internal permanent Completer.
      // On the FIRST attempt we await it to surface any native error.
      // On subsequent retries the completer is already completed (possibly with
      // a stale error), so we skip it and assume success if init() didn't throw.
      bool initialized;
      if (!_isInitializedConsumed) {
        _isInitializedConsumed = true;
        try {
          initialized = await FlutterGemmaPlugin.instance.isInitialized;
          debugPrint('[GemmaLlmService] isInitialized = $initialized');
        } catch (e) {
          debugPrint('[GemmaLlmService] isInitialized threw: $e');
          initialized = false;
        }
      } else {
        // Completer already consumed (stuck from a prior failed attempt).
        // Validate with a quick non-streaming request; if native never initialised
        // this will throw or time-out rather than hanging the EventChannel forever.
        debugPrint(
            '[GemmaLlmService] validating with health-check getResponse');
        try {
          final test = await FlutterGemmaPlugin.instance
              .getResponse(prompt: 'ok')
              .timeout(const Duration(seconds: 30));
          initialized = test != null;
          debugPrint('[GemmaLlmService] health-check result: $test');
        } catch (e) {
          debugPrint('[GemmaLlmService] health-check failed: $e');
          initialized = false;
        }
      }

      if (initialized) {
        _isLoaded = true;
        debugPrint('[GemmaLlmService] Gemma ready');
      } else {
        debugPrint('[GemmaLlmService] native init failed — using fallback');
        await _fallback.initialize();
      }
    } catch (e, st) {
      // Model file corrupt, unsupported device, or native init failed — use fallback
      debugPrint('[GemmaLlmService] init error: $e\n$st');
      await _fallback.initialize();
    }
  }

  @override
  Future<String> generate(String prompt) async {
    if (!_isLoaded) return _fallback.generate(prompt);
    try {
      return await FlutterGemmaPlugin.instance
              .getResponse(prompt: prompt)
              .timeout(const Duration(seconds: 60)) ??
          '';
    } catch (e) {
      debugPrint('[GemmaLlmService] generate error: $e');
      _isLoaded = false;
      return _fallback.generate(prompt);
    }
  }

  @override
  Stream<String> generateStream(String prompt) async* {
    if (!_isLoaded) {
      yield* _fallback.generateStream(prompt);
      return;
    }
    bool gotAny = false;
    try {
      await for (final chunk in FlutterGemmaPlugin.instance
          .getResponseAsync(prompt: prompt)
          // 60 s without a new token → assume native is stuck
          .timeout(const Duration(seconds: 60))) {
        if (chunk != null) {
          gotAny = true;
          yield chunk;
        }
      }
    } catch (e) {
      debugPrint('[GemmaLlmService] generateStream error: $e');
      if (!gotAny) {
        // Native Gemma is unresponsive — disable it so future calls
        // go straight to fallback without hanging.
        _isLoaded = false;
        yield* _fallback.generateStream(prompt);
      }
    }
  }

  @override
  void dispose() {
    _isLoaded = false;
  }
}

/// Fallback template-based LLM service — no model download required.
/// Returns realistic LeetCode-style problems from curated string templates.
class TemplateLlmService implements LlmService {
  bool _isLoaded = false;

  @override
  bool get isModelLoaded => _isLoaded;

  @override
  Future<void> initialize() async {
    _isLoaded = true;
  }

  @override
  Stream<String> generateStream(String prompt) async* {
    final response = await generate(prompt);
    final words = response.split(' ');
    for (int i = 0; i < words.length; i++) {
      yield i == 0 ? words[i] : ' ${words[i]}';
      await Future<void>.delayed(const Duration(milliseconds: 8));
    }
  }

  @override
  Future<String> generate(String prompt) async {
    String category = 'Arrays';
    String difficulty = 'Medium';

    const categoryPatterns = [
      'Arrays',
      'Strings',
      'Trees',
      'Graphs',
      'Dynamic Programming',
      'Binary Search',
      'Two Pointers',
      'Sliding Window',
      'Stack',
      'Heap',
      'Backtracking',
      'Linked List',
    ];
    for (final cat in categoryPatterns) {
      if (prompt.toLowerCase().contains(cat.toLowerCase())) {
        category = cat;
        break;
      }
    }
    for (final diff in ['Easy', 'Medium', 'Hard']) {
      if (prompt.toLowerCase().contains(diff.toLowerCase())) {
        difficulty = diff;
        break;
      }
    }

    return _buildTemplateResponse(category, difficulty);
  }

  @override
  void dispose() {
    _isLoaded = false;
  }

  // ---------------------------------------------------------------------------
  // Template builders
  // ---------------------------------------------------------------------------

  String _buildTemplateResponse(String category, String difficulty) {
    final data = _getTemplateData(category, difficulty);
    final bf = _getBruteForceData(category);
    return '''
## Title
${data['title']}

## Description
${data['description']}

## Examples
${data['examples']}

## Constraints
${data['constraints']}

## Solution Approach
${data['approach']}

## Code
```python
${data['code']}
```

## Time Complexity
${data['time']}

## Space Complexity
${data['space']}

## Brute Force Approach
${bf['approach']}

## Brute Force Code
```python
${bf['code']}
```
''';
  }

  /// Returns a generic brute-force solution for the given algorithm category.
  /// One entry per category — not per difficulty — to keep the template count manageable.
  Map<String, String> _getBruteForceData(String category) {
    switch (category) {
      case 'Arrays':
        return {
          'approach':
              'Check every pair of elements with a nested loop. O(n²) time but no extra space beyond the algorithm\'s own variables.',
          'code': '''def findDuplicate_brute(nums):
    n = len(nums)
    for i in range(n):
        for j in range(i + 1, n):
            if nums[i] == nums[j]:
                return nums[i]
    return -1''',
        };
      case 'Strings':
        return {
          'approach':
              'Sort both strings and compare character-by-character. O(n log n) time and O(n) space for the sorted copies.',
          'code': '''def isAnagram_brute(s, t):
    if len(s) != len(t):
        return False
    return sorted(s) == sorted(t)''',
        };
      case 'Trees':
        return {
          'approach':
              'BFS level-order traversal that counts levels explicitly. Uses O(n) queue space instead of the O(h) implicit call-stack of the recursive DFS approach.',
          'code': '''from collections import deque

def maxDepth_brute(root):
    if root is None:
        return 0
    depth = 0
    queue = deque([root])
    while queue:
        depth += 1
        for _ in range(len(queue)):
            node = queue.popleft()
            if node.left: queue.append(node.left)
            if node.right: queue.append(node.right)
    return depth''',
        };
      case 'Graphs':
        return {
          'approach':
              'DFS with a separate visited matrix instead of in-place mutation. Easier to reason about but uses O(m × n) extra space.',
          'code': '''def numIslands_brute(grid):
    rows, cols = len(grid), len(grid[0])
    visited = [[False] * cols for _ in range(rows)]
    count = 0
    def dfs(r, c):
        if r < 0 or r >= rows or c < 0 or c >= cols:
            return
        if visited[r][c] or grid[r][c] != "1":
            return
        visited[r][c] = True
        for dr, dc in [(1,0),(-1,0),(0,1),(0,-1)]:
            dfs(r+dr, c+dc)
    for r in range(rows):
        for c in range(cols):
            if grid[r][c] == "1" and not visited[r][c]:
                count += 1
                dfs(r, c)
    return count''',
        };
      case 'Dynamic Programming':
        return {
          'approach':
              'Pure recursion without memoization. Re-computes overlapping sub-problems, leading to O(2^n) exponential time instead of O(n) linear DP.',
          'code': '''def climbStairs_brute(n):
    if n <= 2:
        return n
    return climbStairs_brute(n - 1) + climbStairs_brute(n - 2)''',
        };
      case 'Binary Search':
        return {
          'approach':
              'Linear scan through the entire array. O(n) time instead of O(log n), but simple to implement and trivially correct.',
          'code': '''def search_brute(nums, target):
    for i, num in enumerate(nums):
        if num == target:
            return i
    return -1''',
        };
      case 'Two Pointers':
        return {
          'approach':
              'Nested loop checking all pairs. O(n²) time instead of O(n), and does not require the array to be sorted first.',
          'code': '''def isPalindrome_brute(s):
    cleaned = [c.lower() for c in s if c.isalnum()]
    return cleaned == cleaned[::-1]''',
        };
      case 'Sliding Window':
        return {
          'approach':
              'Recompute the sum from scratch for every possible window start. O(n × k) time instead of O(n) with an incremental window.',
          'code': '''def findMaxAverage_brute(nums, k):
    max_avg = float("-inf")
    for i in range(len(nums) - k + 1):
        window_sum = sum(nums[i:i + k])
        max_avg = max(max_avg, window_sum / k)
    return max_avg''',
        };
      case 'Stack':
        return {
          'approach':
              'For each element scan the rest of the array to find the answer. O(n²) time instead of O(n) with a monotonic stack.',
          'code': '''def isValid_brute(s):
    while "()" in s or "[]" in s or "{}" in s:
        s = s.replace("()", "")
        s = s.replace("[]", "")
        s = s.replace("{}", "")
    return s == ""''',
        };
      case 'Heap':
        return {
          'approach':
              'Sort the entire collection upfront, then extract in order. O(n log n) time and O(n) space rather than the heap\'s O(log n) per-operation.',
          'code': '''import bisect

def lastStoneWeight_brute(stones):
    stones = sorted(stones)
    while len(stones) > 1:
        a = stones.pop()
        b = stones.pop()
        if a != b:
            bisect.insort(stones, a - b)
    return stones[0] if stones else 0''',
        };
      case 'Backtracking':
        return {
          'approach':
              'Generate all possible output strings upfront, then filter those that satisfy the constraint. Much less efficient than pruning during generation.',
          'code': '''def letterCasePermutation_brute(s):
    results = [""]
    for c in s:
        if c.isdigit():
            results = [r + c for r in results]
        else:
            lowers = [r + c.lower() for r in results]
            uppers = [r + c.upper() for r in results]
            results = lowers + uppers
    return results''',
        };
      case 'Linked List':
        return {
          'approach':
              'Convert the linked list to a Python list, perform the operation on the array, then reconstruct. O(n) time but O(n) extra space.',
          'code': '''def reverseList_brute(head):
    values = []
    cur = head
    while cur:
        values.append(cur.val)
        cur = cur.next
    cur = head
    for val in reversed(values):
        cur.val = val
        cur = cur.next
    return head''',
        };
      default:
        return {
          'approach':
              'Iterate with nested loops, testing every possible combination until the answer is found. O(n²) time, O(1) extra space.',
          'code': '''def brute_force(arr):
    n = len(arr)
    for i in range(n):
        for j in range(i + 1, n):
            pass  # evaluate pair (arr[i], arr[j])
    return None''',
        };
    }
  }

  Map<String, String> _getTemplateData(String category, String difficulty) {
    switch (category) {
      case 'Arrays':
        return _arraysTemplate(difficulty);
      case 'Strings':
        return _stringsTemplate(difficulty);
      case 'Trees':
        return _treesTemplate(difficulty);
      case 'Graphs':
        return _graphsTemplate(difficulty);
      case 'Dynamic Programming':
        return _dpTemplate(difficulty);
      case 'Binary Search':
        return _binarySearchTemplate(difficulty);
      case 'Two Pointers':
        return _twoPointersTemplate(difficulty);
      case 'Sliding Window':
        return _slidingWindowTemplate(difficulty);
      case 'Stack':
        return _stackTemplate(difficulty);
      case 'Heap':
        return _heapTemplate(difficulty);
      case 'Backtracking':
        return _backtrackingTemplate(difficulty);
      case 'Linked List':
        return _linkedListTemplate(difficulty);
      default:
        return _arraysTemplate(difficulty);
    }
  }

  Map<String, String> _arraysTemplate(String difficulty) {
    if (difficulty == 'Easy') {
      return {
        'title': 'Spot the Repeated Element',
        'description':
            'Given an array of integers nums containing n + 1 integers where each integer is in the range [1, n] inclusive, return the one repeated number. You must solve the problem without modifying the array and using only constant extra space.',
        'examples':
            'Input: nums = [1,3,4,2,2]\nOutput: 2\n\nInput: nums = [3,1,3,4,2]\nOutput: 3',
        'constraints':
            '1 <= n <= 10^5\nnums.length == n + 1\n1 <= nums[i] <= n',
        'approach':
            "Use Floyd's cycle detection. Treat each value as a pointer to the next index. A cycle exists because of the duplicate. The cycle entrance is the duplicate number.",
        'code': '''def findDuplicate(nums):
    slow = nums[0]
    fast = nums[0]
    while True:
        slow = nums[slow]
        fast = nums[nums[fast]]
        if slow == fast:
            break
    slow = nums[0]
    while slow != fast:
        slow = nums[slow]
        fast = nums[fast]
    return slow''',
        'time': 'O(n)',
        'space': 'O(1)',
      };
    } else if (difficulty == 'Medium') {
      return {
        'title': 'Array Multiplication Without Current',
        'description':
            'Given an integer array nums, return an array answer such that answer[i] is equal to the product of all the elements of nums except nums[i]. Must run in O(n) without division.',
        'examples': 'Input: nums = [1,2,3,4]\nOutput: [24,12,8,6]',
        'constraints': '2 <= nums.length <= 10^5\n-30 <= nums[i] <= 30',
        'approach':
            'Use prefix and suffix product arrays. First pass: compute prefix products. Second pass: multiply by suffix using a running variable.',
        'code': '''def productExceptSelf(nums):
    n = len(nums)
    result = [1] * n
    prefix = 1
    for i in range(n):
        result[i] = prefix
        prefix *= nums[i]
    suffix = 1
    for i in range(n - 1, -1, -1):
        result[i] *= suffix
        suffix *= nums[i]
    return result''',
        'time': 'O(n)',
        'space': 'O(1) excluding output array',
      };
    } else {
      return {
        'title': 'Longest Unbroken Number Chain',
        'description':
            'Given an unsorted array of integers nums, return the length of the longest consecutive elements sequence. Must run in O(n) time.',
        'examples':
            'Input: nums = [100,4,200,1,3,2]\nOutput: 4\nExplanation: [1,2,3,4]',
        'constraints': '0 <= nums.length <= 10^5\n-10^9 <= nums[i] <= 10^9',
        'approach':
            'Convert nums to a set for O(1) lookup. For each number that is the start of a sequence (num-1 not in set), extend as far as possible.',
        'code': '''def longestConsecutive(nums):
    num_set = set(nums)
    best = 0
    for n in num_set:
        if n - 1 not in num_set:
            cur, length = n, 1
            while cur + 1 in num_set:
                cur += 1
                length += 1
            best = max(best, length)
    return best''',
        'time': 'O(n)',
        'space': 'O(n)',
      };
    }
  }

  Map<String, String> _stringsTemplate(String difficulty) {
    if (difficulty == 'Easy') {
      return {
        'title': 'Check Character Rearrangement',
        'description':
            'Given two strings s and t, return true if t is an anagram of s, and false otherwise.',
        'examples':
            'Input: s = "anagram", t = "nagaram"\nOutput: true\n\nInput: s = "rat", t = "car"\nOutput: false',
        'constraints':
            '1 <= s.length, t.length <= 5 * 10^4\ns and t consist of lowercase English letters.',
        'approach':
            'Count character frequencies with a hash map. Increment for each char in s, decrement for each in t. Valid if all counts are zero.',
        'code': '''def isAnagram(s, t):
    if len(s) != len(t):
        return False
    count = {}
    for c in s:
        count[c] = count.get(c, 0) + 1
    for c in t:
        if count.get(c, 0) == 0:
            return False
        count[c] -= 1
    return True''',
        'time': 'O(n)',
        'space': 'O(1)',
      };
    } else if (difficulty == 'Medium') {
      return {
        'title': 'Widest Mirror Substring',
        'description':
            'Given a string s, return the longest palindromic substring in s.',
        'examples':
            'Input: s = "babad"\nOutput: "bab"\n\nInput: s = "cbbd"\nOutput: "bb"',
        'constraints':
            '1 <= s.length <= 1000\ns consists of only digits and English letters.',
        'approach':
            'Expand around center. For each character, expand outward as long as characters match. Track the longest palindrome found.',
        'code': '''def longestPalindrome(s):
    def expand(l, r):
        while l >= 0 and r < len(s) and s[l] == s[r]:
            l -= 1
            r += 1
        return s[l + 1:r]
    result = ""
    for i in range(len(s)):
        for p in [expand(i, i), expand(i, i + 1)]:
            if len(p) > len(result):
                result = p
    return result''',
        'time': 'O(n^2)',
        'space': 'O(1)',
      };
    } else {
      return {
        'title': 'Smallest Covering Window',
        'description':
            'Given strings s and t, return the minimum window substring of s such that every character in t is included. Return "" if no such window exists.',
        'examples': 'Input: s = "ADOBECODEBANC", t = "ABC"\nOutput: "BANC"',
        'constraints':
            '1 <= m, n <= 10^5\ns and t consist of uppercase and lowercase English letters.',
        'approach':
            'Sliding window with two frequency maps. Expand right to include all required chars, shrink left to minimize window.',
        'code': '''from collections import Counter

def minWindow(s, t):
    need, missing = Counter(t), len(t)
    best_l, best_r = 0, float("inf")
    l = 0
    for r, c in enumerate(s):
        if need[c] > 0:
            missing -= 1
        need[c] -= 1
        if missing == 0:
            while need[s[l]] < 0:
                need[s[l]] += 1
                l += 1
            if r - l < best_r - best_l:
                best_l, best_r = l, r
            need[s[l]] += 1
            missing += 1
            l += 1
    return "" if best_r == float("inf") else s[best_l:best_r + 1]''',
        'time': 'O(m + n)',
        'space': 'O(m + n)',
      };
    }
  }

  Map<String, String> _treesTemplate(String difficulty) {
    if (difficulty == 'Easy') {
      return {
        'title': 'Deepest Branch Length',
        'description':
            "Given the root of a binary tree, return its maximum depth.",
        'examples': 'Input: root = [3,9,20,null,null,15,7]\nOutput: 3',
        'constraints': 'The number of nodes is in the range [0, 10^4].',
        'approach':
            'Recursive DFS. Depth = 1 + max(depth(left), depth(right)). Base case: None returns 0.',
        'code': '''def maxDepth(root):
    if root is None:
        return 0
    return 1 + max(maxDepth(root.left), maxDepth(root.right))''',
        'time': 'O(n)',
        'space': 'O(h)',
      };
    } else if (difficulty == 'Medium') {
      return {
        'title': 'Layer-by-Layer Tree Walk',
        'description':
            "Return the level order traversal of a binary tree's node values.",
        'examples':
            'Input: root = [3,9,20,null,null,15,7]\nOutput: [[3],[9,20],[15,7]]',
        'constraints': 'The number of nodes is in the range [0, 2000].',
        'approach': 'BFS with a queue. Process nodes level by level.',
        'code': '''from collections import deque

def levelOrder(root):
    if not root:
        return []
    result, queue = [], deque([root])
    while queue:
        level = []
        for _ in range(len(queue)):
            node = queue.popleft()
            level.append(node.val)
            if node.left: queue.append(node.left)
            if node.right: queue.append(node.right)
        result.append(level)
    return result''',
        'time': 'O(n)',
        'space': 'O(n)',
      };
    } else {
      return {
        'title': 'Tree Snapshot and Rebuild',
        'description':
            'Design an algorithm to serialize and deserialize a binary tree.',
        'examples':
            'Input: root = [1,2,3,null,null,4,5]\nOutput: [1,2,3,null,null,4,5]',
        'constraints': 'The number of nodes is in the range [0, 10^4].',
        'approach':
            'Serialize via preorder DFS using "null" for missing nodes. Deserialize by reconstructing in the same preorder.',
        'code': '''from collections import deque

class Codec:
    def serialize(self, root):
        res = []
        def dfs(node):
            if not node:
                res.append("null")
                return
            res.append(str(node.val))
            dfs(node.left)
            dfs(node.right)
        dfs(root)
        return ",".join(res)

    def deserialize(self, data):
        tokens = deque(data.split(","))
        def dfs():
            val = tokens.popleft()
            if val == "null":
                return None
            node = TreeNode(int(val))
            node.left = dfs()
            node.right = dfs()
            return node
        return dfs()''',
        'time': 'O(n)',
        'space': 'O(n)',
      };
    }
  }

  Map<String, String> _graphsTemplate(String difficulty) {
    if (difficulty == 'Easy') {
      return {
        'title': 'Count Land Clusters',
        'description':
            'Given an m x n 2D binary grid of "1"s (land) and "0"s (water), return the number of islands.',
        'examples':
            'Input: grid = [["1","1","0"],["0","1","0"],["0","0","1"]]\nOutput: 2',
        'constraints': '1 <= m, n <= 300',
        'approach':
            'DFS. When a "1" is found, increment count and DFS to mark all connected land as visited.',
        'code': '''def numIslands(grid):
    rows, cols = len(grid), len(grid[0])
    count = 0
    def dfs(r, c):
        if r < 0 or r >= rows or c < 0 or c >= cols or grid[r][c] != "1":
            return
        grid[r][c] = "0"
        for dr, dc in [(1,0),(-1,0),(0,1),(0,-1)]:
            dfs(r+dr, c+dc)
    for r in range(rows):
        for c in range(cols):
            if grid[r][c] == "1":
                count += 1
                dfs(r, c)
    return count''',
        'time': 'O(m * n)',
        'space': 'O(m * n)',
      };
    } else if (difficulty == 'Medium') {
      return {
        'title': 'Deep Copy a Graph',
        'description':
            'Given a reference of a node in a connected undirected graph, return a deep copy of the graph.',
        'examples':
            'Input: adjList = [[2,4],[1,3],[2,4],[1,3]]\nOutput: [[2,4],[1,3],[2,4],[1,3]]',
        'constraints': 'The number of nodes is in the range [0, 100].',
        'approach': 'BFS with a visited map from original nodes to clones.',
        'code': '''from collections import deque

def cloneGraph(node):
    if not node:
        return None
    cloned = {node: Node(node.val)}
    queue = deque([node])
    while queue:
        cur = queue.popleft()
        for neighbor in cur.neighbors:
            if neighbor not in cloned:
                cloned[neighbor] = Node(neighbor.val)
                queue.append(neighbor)
            cloned[cur].neighbors.append(cloned[neighbor])
    return cloned[node]''',
        'time': 'O(V + E)',
        'space': 'O(V)',
      };
    } else {
      return {
        'title': 'Minimum Word Transformation Steps',
        'description':
            'Return the number of words in the shortest transformation sequence from beginWord to endWord, or 0 if none exists.',
        'examples':
            'Input: beginWord = "hit", endWord = "cog", wordList = ["hot","dot","dog","lot","log","cog"]\nOutput: 5',
        'constraints': '1 <= beginWord.length <= 10',
        'approach':
            'BFS from beginWord. Try changing each character to every letter a-z and check if in word set.',
        'code': '''from collections import deque

def ladderLength(beginWord, endWord, wordList):
    word_set = set(wordList)
    if endWord not in word_set:
        return 0
    queue = deque([(beginWord, 1)])
    visited = {beginWord}
    while queue:
        word, steps = queue.popleft()
        for i in range(len(word)):
            for c in "abcdefghijklmnopqrstuvwxyz":
                new_word = word[:i] + c + word[i+1:]
                if new_word == endWord:
                    return steps + 1
                if new_word in word_set and new_word not in visited:
                    visited.add(new_word)
                    queue.append((new_word, steps + 1))
    return 0''',
        'time': 'O(M^2 * N)',
        'space': 'O(M^2 * N)',
      };
    }
  }

  Map<String, String> _dpTemplate(String difficulty) {
    if (difficulty == 'Easy') {
      return {
        'title': 'Count Ways to Climb Steps',
        'description':
            'It takes n steps to reach the top. Each time you can climb 1 or 2 steps. How many distinct ways can you climb?',
        'examples': 'Input: n = 3\nOutput: 3\nExplanation: 1+1+1, 1+2, 2+1',
        'constraints': '1 <= n <= 45',
        'approach':
            'Classic Fibonacci DP. dp[i] = dp[i-1] + dp[i-2]. Space-optimized to O(1).',
        'code': '''def climbStairs(n):
    if n <= 2:
        return n
    a, b = 1, 2
    for _ in range(3, n + 1):
        a, b = b, a + b
    return b''',
        'time': 'O(n)',
        'space': 'O(1)',
      };
    } else if (difficulty == 'Medium') {
      return {
        'title': 'Fewest Coins for Target Amount',
        'description':
            'Given coins and an amount, return the fewest coins to make that amount, or -1 if impossible.',
        'examples':
            'Input: coins = [1,5,11], amount = 11\nOutput: 1\n\nInput: coins = [2], amount = 3\nOutput: -1',
        'constraints': '1 <= coins.length <= 12\n0 <= amount <= 10^4',
        'approach': 'Bottom-up DP. dp[i] = minimum coins to make amount i.',
        'code': '''def coinChange(coins, amount):
    dp = [float("inf")] * (amount + 1)
    dp[0] = 0
    for i in range(1, amount + 1):
        for coin in coins:
            if coin <= i:
                dp[i] = min(dp[i], dp[i - coin] + 1)
    return dp[amount] if dp[amount] != float("inf") else -1''',
        'time': 'O(amount * len(coins))',
        'space': 'O(amount)',
      };
    } else {
      return {
        'title': 'Minimum String Transformation Cost',
        'description':
            'Return the minimum number of operations (insert, delete, replace) to convert word1 to word2.',
        'examples': 'Input: word1 = "horse", word2 = "ros"\nOutput: 3',
        'constraints': '0 <= word1.length, word2.length <= 500',
        'approach':
            '2D DP. dp[i][j] = edit distance between word1[:i] and word2[:j].',
        'code': '''def minDistance(word1, word2):
    m, n = len(word1), len(word2)
    dp = [[0] * (n + 1) for _ in range(m + 1)]
    for i in range(m + 1): dp[i][0] = i
    for j in range(n + 1): dp[0][j] = j
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if word1[i-1] == word2[j-1]:
                dp[i][j] = dp[i-1][j-1]
            else:
                dp[i][j] = 1 + min(dp[i-1][j], dp[i][j-1], dp[i-1][j-1])
    return dp[m][n]''',
        'time': 'O(m * n)',
        'space': 'O(m * n)',
      };
    }
  }

  Map<String, String> _binarySearchTemplate(String difficulty) {
    if (difficulty == 'Easy') {
      return {
        'title': 'Index Finder in Sorted List',
        'description':
            'Given a sorted array and a target, return its index or -1.',
        'examples': 'Input: nums = [-1,0,3,5,9,12], target = 9\nOutput: 4',
        'constraints': '1 <= nums.length <= 10^4',
        'approach': 'Classic binary search with lo/hi/mid.',
        'code': '''def search(nums, target):
    lo, hi = 0, len(nums) - 1
    while lo <= hi:
        mid = lo + (hi - lo) // 2
        if nums[mid] == target:
            return mid
        elif nums[mid] < target:
            lo = mid + 1
        else:
            hi = mid - 1
    return -1''',
        'time': 'O(log n)',
        'space': 'O(1)',
      };
    } else if (difficulty == 'Medium') {
      return {
        'title': 'Find Element in Rotated List',
        'description':
            'Search for target in a rotated sorted array with distinct values.',
        'examples': 'Input: nums = [4,5,6,7,0,1,2], target = 0\nOutput: 4',
        'constraints': '1 <= nums.length <= 5000',
        'approach':
            'At least one half is always sorted. Determine which half, check if target is in it.',
        'code': '''def search(nums, target):
    lo, hi = 0, len(nums) - 1
    while lo <= hi:
        mid = lo + (hi - lo) // 2
        if nums[mid] == target:
            return mid
        if nums[lo] <= nums[mid]:
            if nums[lo] <= target < nums[mid]:
                hi = mid - 1
            else:
                lo = mid + 1
        else:
            if nums[mid] < target <= nums[hi]:
                lo = mid + 1
            else:
                hi = mid - 1
    return -1''',
        'time': 'O(log n)',
        'space': 'O(1)',
      };
    } else {
      return {
        'title': 'Smallest Value After Rotation',
        'description':
            'Find the minimum in a rotated sorted array that may contain duplicates.',
        'examples': 'Input: nums = [2,2,2,0,1]\nOutput: 0',
        'constraints': '1 <= nums.length <= 5000',
        'approach':
            'Binary search variant. When nums[mid] == nums[hi], shrink hi by 1.',
        'code': '''def findMin(nums):
    lo, hi = 0, len(nums) - 1
    while lo < hi:
        mid = lo + (hi - lo) // 2
        if nums[mid] > nums[hi]:
            lo = mid + 1
        elif nums[mid] < nums[hi]:
            hi = mid
        else:
            hi -= 1
    return nums[lo]''',
        'time': 'O(log n) avg, O(n) worst',
        'space': 'O(1)',
      };
    }
  }

  Map<String, String> _twoPointersTemplate(String difficulty) {
    if (difficulty == 'Easy') {
      return {
        'title': 'Alphanumeric Mirror Check',
        'description':
            'After removing non-alphanumeric characters and lowercasing, return true if the string is a palindrome.',
        'examples': 'Input: s = "A man, a plan, a canal: Panama"\nOutput: true',
        'constraints': '1 <= s.length <= 2 * 10^5',
        'approach':
            'Two pointers from each end, skipping non-alphanumeric characters.',
        'code': '''def isPalindrome(s):
    l, r = 0, len(s) - 1
    while l < r:
        while l < r and not s[l].isalnum(): l += 1
        while l < r and not s[r].isalnum(): r -= 1
        if s[l].lower() != s[r].lower():
            return False
        l += 1; r -= 1
    return True''',
        'time': 'O(n)',
        'space': 'O(1)',
      };
    } else if (difficulty == 'Medium') {
      return {
        'title': 'Zero-Sum Triplets',
        'description':
            'Return all unique triplets in the array that sum to zero.',
        'examples':
            'Input: nums = [-1,0,1,2,-1,-4]\nOutput: [[-1,-1,2],[-1,0,1]]',
        'constraints': '3 <= nums.length <= 3000',
        'approach':
            'Sort, fix first element, use two pointers for the remaining pair.',
        'code': '''def threeSum(nums):
    nums.sort()
    result = []
    for i, a in enumerate(nums):
        if i > 0 and nums[i] == nums[i - 1]:
            continue
        l, r = i + 1, len(nums) - 1
        while l < r:
            total = a + nums[l] + nums[r]
            if total < 0: l += 1
            elif total > 0: r -= 1
            else:
                result.append([a, nums[l], nums[r]])
                l += 1
                while l < r and nums[l] == nums[l - 1]:
                    l += 1
    return result''',
        'time': 'O(n^2)',
        'space': 'O(1)',
      };
    } else {
      return {
        'title': 'Rainwater Accumulation Between Walls',
        'description':
            'Given elevation map heights, compute how much water can be trapped.',
        'examples': 'Input: height = [0,1,0,2,1,0,1,3,2,1,2,1]\nOutput: 6',
        'constraints': '1 <= height.length <= 2 * 10^4',
        'approach':
            'Two pointers. Track maxLeft and maxRight. Process from the side with the smaller max.',
        'code': '''def trap(height):
    l, r = 0, len(height) - 1
    max_l = max_r = water = 0
    while l < r:
        if height[l] <= height[r]:
            if height[l] >= max_l: max_l = height[l]
            else: water += max_l - height[l]
            l += 1
        else:
            if height[r] >= max_r: max_r = height[r]
            else: water += max_r - height[r]
            r -= 1
    return water''',
        'time': 'O(n)',
        'space': 'O(1)',
      };
    }
  }

  Map<String, String> _slidingWindowTemplate(String difficulty) {
    if (difficulty == 'Easy') {
      return {
        'title': 'Best Fixed-Length Window Average',
        'description':
            'Find a contiguous subarray of length k with maximum average value.',
        'examples': 'Input: nums = [1,12,-5,-6,50,3], k = 4\nOutput: 12.75',
        'constraints': '1 <= k <= n <= 10^5',
        'approach':
            'Fixed sliding window: compute sum of first k, slide right.',
        'code': '''def findMaxAverage(nums, k):
    window_sum = sum(nums[:k])
    max_sum = window_sum
    for i in range(k, len(nums)):
        window_sum += nums[i] - nums[i - k]
        max_sum = max(max_sum, window_sum)
    return max_sum / k''',
        'time': 'O(n)',
        'space': 'O(1)',
      };
    } else if (difficulty == 'Medium') {
      return {
        'title': 'Longest Non-Repeating Window',
        'description':
            'Find the length of the longest substring without repeating characters.',
        'examples': 'Input: s = "abcabcbb"\nOutput: 3',
        'constraints': '0 <= s.length <= 5 * 10^4',
        'approach':
            'Variable sliding window with a map tracking last seen index.',
        'code': '''def lengthOfLongestSubstring(s):
    seen = {}
    l = best = 0
    for r, c in enumerate(s):
        if c in seen and seen[c] >= l:
            l = seen[c] + 1
        seen[c] = r
        best = max(best, r - l + 1)
    return best''',
        'time': 'O(n)',
        'space': 'O(min(n, 26))',
      };
    } else {
      return {
        'title': 'Rolling Window Peak Values',
        'description': 'Return the max value in each sliding window of size k.',
        'examples':
            'Input: nums = [1,3,-1,-3,5,3,6,7], k = 3\nOutput: [3,3,5,5,6,7]',
        'constraints': '1 <= k <= nums.length <= 10^5',
        'approach':
            'Monotonic deque of indices. Front is always the max of the current window.',
        'code': '''from collections import deque

def maxSlidingWindow(nums, k):
    dq, result = deque(), []
    for r in range(len(nums)):
        while dq and dq[0] < r - k + 1:
            dq.popleft()
        while dq and nums[dq[-1]] < nums[r]:
            dq.pop()
        dq.append(r)
        if r >= k - 1:
            result.append(nums[dq[0]])
    return result''',
        'time': 'O(n)',
        'space': 'O(k)',
      };
    }
  }

  Map<String, String> _stackTemplate(String difficulty) {
    if (difficulty == 'Easy') {
      return {
        'title': 'Balanced Bracket Checker',
        'description': 'Determine if a string of brackets is valid.',
        'examples':
            'Input: s = "()[]{}"\nOutput: true\n\nInput: s = "(]"\nOutput: false',
        'constraints': '1 <= s.length <= 10^4',
        'approach':
            'Stack. Push opening brackets; closing bracket must match top.',
        'code': '''def isValid(s):
    stack = []
    mapping = {")": "(", "}": "{", "]": "["}
    for c in s:
        if c in mapping:
            top = stack.pop() if stack else "#"
            if mapping[c] != top:
                return False
        else:
            stack.append(c)
    return not stack''',
        'time': 'O(n)',
        'space': 'O(n)',
      };
    } else if (difficulty == 'Medium') {
      return {
        'title': 'Days Until Warmer Weather',
        'description':
            'Return array where answer[i] is the number of days until a warmer temperature.',
        'examples':
            'Input: temperatures = [73,74,75,71,69,72,76,73]\nOutput: [1,1,4,2,1,1,0,0]',
        'constraints': '1 <= temperatures.length <= 10^5',
        'approach': 'Monotonic decreasing stack of indices.',
        'code': '''def dailyTemperatures(temperatures):
    n = len(temperatures)
    answer = [0] * n
    stack = []
    for i, temp in enumerate(temperatures):
        while stack and temperatures[stack[-1]] < temp:
            idx = stack.pop()
            answer[idx] = i - idx
        stack.append(i)
    return answer''',
        'time': 'O(n)',
        'space': 'O(n)',
      };
    } else {
      return {
        'title': 'Biggest Rectangle in Bar Chart',
        'description':
            'Return the area of the largest rectangle in the histogram.',
        'examples': 'Input: heights = [2,1,5,6,2,3]\nOutput: 10',
        'constraints': '1 <= heights.length <= 10^5',
        'approach': 'Monotonic increasing stack with sentinel bars.',
        'code': '''def largestRectangleArea(heights):
    heights = [0] + heights + [0]
    stack = []
    max_area = 0
    for i, h in enumerate(heights):
        while stack and heights[stack[-1]] > h:
            height = heights[stack.pop()]
            width = i - stack[-1] - 1
            max_area = max(max_area, height * width)
        stack.append(i)
    return max_area''',
        'time': 'O(n)',
        'space': 'O(n)',
      };
    }
  }

  Map<String, String> _heapTemplate(String difficulty) {
    if (difficulty == 'Easy') {
      return {
        'title': 'Final Stone After Collisions',
        'description':
            'Smash the two heaviest stones repeatedly. Return weight of last stone or 0.',
        'examples': 'Input: stones = [2,7,4,1,8,1]\nOutput: 1',
        'constraints': '1 <= stones.length <= 30',
        'approach':
            'Max heap (negate for Python min-heap). Repeatedly pop two largest.',
        'code': '''import heapq

def lastStoneWeight(stones):
    heap = [-s for s in stones]
    heapq.heapify(heap)
    while len(heap) > 1:
        a = -heapq.heappop(heap)
        b = -heapq.heappop(heap)
        if a != b:
            heapq.heappush(heap, -(a - b))
    return -heap[0] if heap else 0''',
        'time': 'O(n log n)',
        'space': 'O(n)',
      };
    } else if (difficulty == 'Medium') {
      return {
        'title': 'Nearest K Points to Center',
        'description': 'Return the k closest points to origin (0,0).',
        'examples': 'Input: points = [[1,3],[-2,2]], k = 1\nOutput: [[-2,2]]',
        'constraints': '1 <= k <= points.length <= 10^4',
        'approach': 'Min-heap keyed by squared distance.',
        'code': '''import heapq

def kClosest(points, k):
    heap = [(x*x + y*y, x, y) for x, y in points]
    heapq.heapify(heap)
    return [[x, y] for _, x, y in heapq.nsmallest(k, heap)]''',
        'time': 'O(n log k)',
        'space': 'O(n)',
      };
    } else {
      return {
        'title': 'Running Median Calculator',
        'description':
            'Design a data structure supporting addNum and findMedian in O(log n) and O(1).',
        'examples':
            'addNum(1), addNum(2), findMedian() → 1.5, addNum(3), findMedian() → 2.0',
        'constraints': '-10^5 <= num <= 10^5',
        'approach':
            'Two heaps: max-heap for lower half, min-heap for upper half.',
        'code': '''import heapq

class MedianFinder:
    def __init__(self):
        self.lo = []  # max-heap (negated)
        self.hi = []  # min-heap

    def addNum(self, num):
        heapq.heappush(self.lo, -num)
        heapq.heappush(self.hi, -heapq.heappop(self.lo))
        if len(self.hi) > len(self.lo):
            heapq.heappush(self.lo, -heapq.heappop(self.hi))

    def findMedian(self):
        if len(self.lo) > len(self.hi):
            return -self.lo[0]
        return (-self.lo[0] + self.hi[0]) / 2.0''',
        'time': 'O(log n) add, O(1) median',
        'space': 'O(n)',
      };
    }
  }

  Map<String, String> _backtrackingTemplate(String difficulty) {
    if (difficulty == 'Easy') {
      return {
        'title': 'All Case Variations',
        'description':
            'Return all strings by transforming every letter to lowercase or uppercase.',
        'examples': 'Input: s = "a1b2"\nOutput: ["a1b2","a1B2","A1b2","A1B2"]',
        'constraints': '1 <= s.length <= 12',
        'approach':
            'DFS backtracking. For digits recurse directly; for letters branch into both cases.',
        'code': '''def letterCasePermutation(s):
    result = []
    def backtrack(idx, current):
        if idx == len(s):
            result.append(current)
            return
        c = s[idx]
        if c.isdigit():
            backtrack(idx + 1, current + c)
        else:
            backtrack(idx + 1, current + c.lower())
            backtrack(idx + 1, current + c.upper())
    backtrack(0, "")
    return result''',
        'time': 'O(2^n)',
        'space': 'O(n)',
      };
    } else if (difficulty == 'Medium') {
      return {
        'title': 'Repeated-Use Sum Combinations',
        'description':
            'Return all unique combinations that sum to target. Same number may be reused.',
        'examples':
            'Input: candidates = [2,3,6,7], target = 7\nOutput: [[2,2,3],[7]]',
        'constraints': '1 <= candidates.length <= 30',
        'approach':
            'Backtracking. Try each candidate >= current index. Prune if sum exceeds target.',
        'code': '''def combinationSum(candidates, target):
    result = []
    def backtrack(start, current, remaining):
        if remaining == 0:
            result.append(list(current))
            return
        for i in range(start, len(candidates)):
            c = candidates[i]
            if c > remaining:
                continue
            current.append(c)
            backtrack(i, current, remaining - c)
            current.pop()
    backtrack(0, [], target)
    return result''',
        'time': 'O(N^(T/M))',
        'space': 'O(T/M)',
      };
    } else {
      return {
        'title': 'Non-Attacking Queen Placements',
        'description': 'Return all distinct solutions to the N-Queens puzzle.',
        'examples':
            'Input: n = 4\nOutput: [[".Q..","...Q","Q...","..Q."],["..Q.","Q...","...Q",".Q.."]]',
        'constraints': '1 <= n <= 9',
        'approach':
            'Backtracking row by row. Track cols, diagonals, anti-diagonals with sets.',
        'code': '''def solveNQueens(n):
    cols, diag, anti = set(), set(), set()
    board = [["."] * n for _ in range(n)]
    result = []
    def backtrack(row):
        if row == n:
            result.append(["".join(r) for r in board])
            return
        for col in range(n):
            if col in cols or (row-col) in diag or (row+col) in anti:
                continue
            cols.add(col); diag.add(row-col); anti.add(row+col)
            board[row][col] = "Q"
            backtrack(row + 1)
            cols.remove(col); diag.remove(row-col); anti.remove(row+col)
            board[row][col] = "."
    backtrack(0)
    return result''',
        'time': 'O(n!)',
        'space': 'O(n^2)',
      };
    }
  }

  Map<String, String> _linkedListTemplate(String difficulty) {
    if (difficulty == 'Easy') {
      return {
        'title': 'Flip a Chain of Nodes',
        'description':
            'Reverse a singly linked list and return the reversed list.',
        'examples': 'Input: head = [1,2,3,4,5]\nOutput: [5,4,3,2,1]',
        'constraints': '0 <= nodes <= 5000',
        'approach':
            'Iterative: keep prev=None, cur=head. Point cur.next to prev and advance.',
        'code': '''def reverseList(head):
    prev = None
    cur = head
    while cur:
        nxt = cur.next
        cur.next = prev
        prev = cur
        cur = nxt
    return prev''',
        'time': 'O(n)',
        'space': 'O(1)',
      };
    } else if (difficulty == 'Medium') {
      return {
        'title': 'Sum Two Reversed-Digit Numbers',
        'description': 'Add two numbers represented as reversed linked lists.',
        'examples':
            'Input: l1 = [2,4,3], l2 = [5,6,4]\nOutput: [7,0,8] (342 + 465 = 807)',
        'constraints': '1 <= nodes <= 100',
        'approach': 'Simulate digit-by-digit addition with carry.',
        'code': '''def addTwoNumbers(l1, l2):
    dummy = cur = ListNode(0)
    carry = 0
    while l1 or l2 or carry:
        val = carry
        if l1: val += l1.val; l1 = l1.next
        if l2: val += l2.val; l2 = l2.next
        carry, val = divmod(val, 10)
        cur.next = ListNode(val)
        cur = cur.next
    return dummy.next''',
        'time': 'O(max(m,n))',
        'space': 'O(max(m,n))',
      };
    } else {
      return {
        'title': 'Reverse Every K Nodes',
        'description': 'Reverse every k nodes in a linked list.',
        'examples': 'Input: head = [1,2,3,4,5], k = 2\nOutput: [2,1,4,3,5]',
        'constraints': '1 <= k <= nodes <= 5000',
        'approach':
            'Check k nodes remain. Reverse k nodes in place, link to recursively reversed rest.',
        'code': '''def reverseKGroup(head, k):
    def reverse(node, k):
        prev = None
        cur = node
        for _ in range(k):
            nxt = cur.next
            cur.next = prev
            prev = cur
            cur = nxt
        return prev
    count, cur = 0, head
    while cur and count < k:
        cur = cur.next
        count += 1
    if count < k:
        return head
    new_head = reverse(head, k)
    head.next = reverseKGroup(cur, k)
    return new_head''',
        'time': 'O(n)',
        'space': 'O(n/k)',
      };
    }
  }
}
