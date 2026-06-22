import '../models/technique.dart';

class TrainingData {
  static final List<Technique> techniques = [
    // -------------------------------------------------------------------------
    // 1. Two Pointers
    // -------------------------------------------------------------------------
    const Technique(
      id: 'two-pointers',
      name: 'Two Pointers',
      category: 'Fundamental',
      icon: '👆',
      difficulty: 'Beginner',
      shortDescription:
          'Use two index pointers moving toward each other or in the same direction to solve array problems in linear time.',
      fullDescription:
          'The Two Pointers technique uses two index variables that traverse a data structure simultaneously, either moving toward each other (converging) or in the same direction at different speeds (fast/slow). It is most powerful on sorted arrays where the relationship between elements at the two pointers drives the decision of which pointer to advance.\n\n'
          'Converging pointers start at opposite ends and move inward — useful for finding pairs that satisfy a sum condition or checking palindromes. Fast/slow pointers both start at the head and move at different speeds — the classic application is Floyd\'s cycle detection in linked lists.',
      keyPatterns: [
        'Left/Right pointers converging from both ends (sorted array sums, palindromes)',
        'Fast/Slow pointers (cycle detection, finding middle of linked list)',
        'Partition pointers (Dutch National Flag, QuickSort partition)',
      ],
      steps: [
        TechniqueStep(
          stepNumber: 1,
          title: 'Initialize pointers',
          description:
              'Place left (l) at index 0 and right (r) at the last index. For fast/slow, both start at the head.',
        ),
        TechniqueStep(
          stepNumber: 2,
          title: 'Define the movement condition',
          description:
              'Continue the loop while l < r (or while fast and fast.next exist for linked lists). The condition depends on the problem variant.',
        ),
        TechniqueStep(
          stepNumber: 3,
          title: 'Update pointers based on comparison',
          description:
              'Compare elements at l and r against the target condition. Move l right if current sum is too small; move r left if too large; record result and move both if matched.',
        ),
      ],
      codeExamples: [
        CodeExample(
          title: 'Two Sum II — sorted array',
          language: 'python',
          explanation:
              'Find two indices (1-indexed) in a sorted array whose values sum to target. Converging pointers give O(n) time without extra space.',
          code: '''def twoSum(numbers, target):
    l, r = 0, len(numbers) - 1
    while l < r:
        total = numbers[l] + numbers[r]
        if total == target:
            return [l + 1, r + 1]   # 1-indexed output
        elif total < target:
            l += 1   # need a larger number
        else:
            r -= 1   # need a smaller number
    return []   # guaranteed to have a solution per problem statement''',
        ),
        CodeExample(
          title: 'Detect cycle in linked list (Floyd\'s algorithm)',
          language: 'python',
          explanation:
              'Fast pointer moves 2 steps, slow moves 1. If a cycle exists they will meet inside it.',
          code: '''class ListNode:
    def __init__(self, val=0, next=None):
        self.val = val
        self.next = next

def hasCycle(head):
    slow = fast = head
    while fast and fast.next:
        slow = slow.next
        fast = fast.next.next
        if slow is fast:
            return True
    return False''',
        ),
      ],
      timeComplexity: 'O(n)',
      spaceComplexity: 'O(1)',
      tips: [
        'Works best on sorted arrays — sort first if needed (adds O(n log n)).',
        'For fast/slow pointers, always check fast and fast.next before advancing.',
        'Consider edge cases with equal elements — decide whether to skip duplicates.',
        'When the array has 3 elements to sum (3Sum), fix one element and use two pointers on the rest.',
      ],
      commonMistakes: [
        'Forgetting to check l < r; an off-by-one moves pointers past each other.',
        'Infinite loop when both pointers should advance but only one does.',
        'Not handling duplicates in 3Sum — always skip equal elements after recording.',
        'Using two pointers on an unsorted array without sorting first.',
      ],
      relatedProblems: [
        'Two Sum II',
        'Valid Palindrome',
        '3Sum',
        'Container With Most Water',
        'Linked List Cycle',
        'Remove Duplicates from Sorted Array',
      ],
    ),

    // -------------------------------------------------------------------------
    // 2. Sliding Window
    // -------------------------------------------------------------------------
    const Technique(
      id: 'sliding-window',
      name: 'Sliding Window',
      category: 'Fundamental',
      icon: '🪟',
      difficulty: 'Beginner',
      shortDescription:
          'Maintain a dynamic window of elements, expanding and shrinking it based on a constraint to find optimal subarrays/substrings.',
      fullDescription:
          'The Sliding Window technique avoids recomputing information about a subarray from scratch each time. A window defined by two pointers (left and right) slides over the data structure. The right pointer expands the window to include new elements; the left pointer shrinks it when the constraint is violated.\n\n'
          'Fixed-size windows are simpler: the left pointer advances in lockstep with the right. Variable-size windows let the left pointer jump ahead whenever the window no longer satisfies the constraint, making them suitable for "longest/shortest subarray with property X" problems.',
      keyPatterns: [
        'Fixed-size window: maximum/minimum sum of k consecutive elements',
        'Variable window with a validity condition: longest substring without repeats',
        'Window with a frequency map: minimum window containing all required characters',
      ],
      steps: [
        TechniqueStep(
          stepNumber: 1,
          title: 'Initialize window and tracking state',
          description:
              'Set left = right = 0. Create a counter, sum, or set to track the window\'s current state.',
        ),
        TechniqueStep(
          stepNumber: 2,
          title: 'Expand the window (advance right)',
          description:
              'Move right pointer one step at a time, updating the window state (add the new element to the counter/sum).',
        ),
        TechniqueStep(
          stepNumber: 3,
          title: 'Shrink the window when constraint is violated',
          description:
              'While the window violates the constraint, advance the left pointer and remove the departing element from the tracking state.',
        ),
        TechniqueStep(
          stepNumber: 4,
          title: 'Record the answer',
          description:
              'After each expansion (and shrink), check if the current window gives a better answer than the best seen so far.',
        ),
      ],
      codeExamples: [
        CodeExample(
          title: 'Maximum Sum Subarray of Size K',
          language: 'python',
          explanation:
              'Classic fixed-size window. O(n) by adding the new element and subtracting the element that leaves the window.',
          code: '''def maxSumSubarrayOfSizeK(nums, k):
    window_sum = sum(nums[:k])
    max_sum = window_sum
    for i in range(k, len(nums)):
        window_sum += nums[i] - nums[i - k]
        max_sum = max(max_sum, window_sum)
    return max_sum''',
        ),
        CodeExample(
          title: 'Longest Substring Without Repeating Characters',
          language: 'python',
          explanation:
              'Variable window. A dict stores the last seen index of each character, allowing the left pointer to jump past duplicates in O(1).',
          code: '''def lengthOfLongestSubstring(s):
    seen = {}   # char -> last seen index
    l = 0
    best = 0
    for r, c in enumerate(s):
        # If c was seen inside the current window, shrink from the left
        if c in seen and seen[c] >= l:
            l = seen[c] + 1
        seen[c] = r
        best = max(best, r - l + 1)
    return best''',
        ),
      ],
      timeComplexity: 'O(n)',
      spaceComplexity: 'O(1) for fixed window, O(k) for window with a map',
      tips: [
        'Use a hash map when you need to track character frequencies inside the window.',
        'For "at most K distinct characters" problems, the outer loop is O(n) even though inner shrinking looks O(n) — each element enters and exits at most once.',
        'Fixed windows are easier: just add nums[r] and subtract nums[r-k].',
        'When the problem says "subarray" with a sum constraint, try a prefix-sum + hash map first; sliding window only works when all values are positive.',
      ],
      commonMistakes: [
        'Forgetting to update the tracking state when the left pointer advances.',
        'Using sliding window for negative numbers without adapting (the window may need to shrink even when sum is below target).',
        'Off-by-one when computing the window length: it is r - l + 1.',
        'Not resetting the window state correctly when starting a new window.',
      ],
      relatedProblems: [
        'Longest Substring Without Repeating Characters',
        'Minimum Window Substring',
        'Permutation in String',
        'Longest Repeating Character Replacement',
        'Sliding Window Maximum',
      ],
    ),

    // -------------------------------------------------------------------------
    // 3. Binary Search
    // -------------------------------------------------------------------------
    const Technique(
      id: 'binary-search',
      name: 'Binary Search',
      category: 'Fundamental',
      icon: '🔍',
      difficulty: 'Beginner',
      shortDescription:
          'Eliminate half the search space each iteration. Works on sorted data or any problem where the answer space is monotonic.',
      fullDescription:
          'Binary Search works by repeatedly halving the candidate range. In each iteration the algorithm inspects the midpoint; based on how the midpoint compares to the target, it discards the half that cannot contain the answer.\n\n'
          'Beyond classic element search, binary search applies to "search on answer" problems: if you can write a function isValid(x) that is monotonically false → true (or true → false) over some integer range, binary search finds the boundary in O(log n) iterations.\n\n'
          'Common pitfalls are the choice of mid = lo + (hi-lo)//2 (prevents integer overflow compared to (lo+hi)//2) and the exact loop termination condition (lo <= hi vs lo < hi).',
      keyPatterns: [
        'Classic binary search: find target in sorted array',
        'Search on answer: find minimum/maximum value satisfying a predicate',
        'Rotated sorted array: determine which half is sorted, then narrow',
        'Finding boundaries: first/last occurrence of a value',
      ],
      steps: [
        TechniqueStep(
          stepNumber: 1,
          title: 'Define the search space',
          description:
              'Set lo = 0 (or the minimum possible answer) and hi = len(nums)-1 (or the maximum possible answer).',
        ),
        TechniqueStep(
          stepNumber: 2,
          title: 'Compute mid safely',
          description:
              'Use mid = lo + (hi - lo) // 2 to avoid overflow in languages with fixed-width integers.',
        ),
        TechniqueStep(
          stepNumber: 3,
          title: 'Evaluate the midpoint',
          description:
              'Compare nums[mid] to the target (or evaluate the predicate at mid). Decide which half to keep.',
        ),
        TechniqueStep(
          stepNumber: 4,
          title: 'Narrow the range',
          description:
              'If mid is too small, set lo = mid + 1. If too large, set hi = mid - 1. Repeat until lo > hi.',
        ),
      ],
      codeExamples: [
        CodeExample(
          title: 'Classic Binary Search',
          language: 'python',
          explanation:
              'Finds the index of target in a sorted array, or -1 if absent. Template for the majority of binary search problems.',
          code: '''def binarySearch(nums, target):
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
        ),
        CodeExample(
          title: 'Search Insert Position (binary search on answer)',
          language: 'python',
          explanation:
              'Returns the index where target would be inserted to keep sorted order. Demonstrates the lo = mid+1 / hi = mid pattern for finding the leftmost valid position.',
          code: '''def searchInsert(nums, target):
    lo, hi = 0, len(nums)   # hi can equal len(nums) if target > all elements
    while lo < hi:
        mid = lo + (hi - lo) // 2
        if nums[mid] < target:
            lo = mid + 1
        else:
            hi = mid   # mid might be the answer; keep it in range
    return lo''',
        ),
      ],
      timeComplexity: 'O(log n)',
      spaceComplexity: 'O(1)',
      tips: [
        'Use mid = lo + (hi-lo)//2 to prevent overflow (critical in Java/C++; Python ints are unbounded but it\'s good habit).',
        'For "search on answer", translate the problem into "find the smallest x where f(x) is True".',
        'The loop invariant lo <= hi (termination condition) vs lo < hi depends on whether you want the exact element or the insertion boundary.',
        'After the loop, lo is the smallest index where the condition holds — useful for lower_bound / upper_bound patterns.',
      ],
      commonMistakes: [
        'Infinite loop when lo == hi and you set hi = mid instead of hi = mid - 1.',
        'Off-by-one on the initial hi value for "insert position" style problems.',
        'Forgetting that binary search requires a sorted (or monotonic) search space.',
        'Not handling the case where the target is absent (return -1 after the loop).',
      ],
      relatedProblems: [
        'Binary Search',
        'Search Insert Position',
        'Find Peak Element',
        'Koko Eating Bananas',
        'Search in Rotated Sorted Array',
        'Capacity To Ship Packages',
      ],
    ),

    // -------------------------------------------------------------------------
    // 4. BFS / Tree Traversal
    // -------------------------------------------------------------------------
    const Technique(
      id: 'bfs-trees',
      name: 'BFS / Tree Traversal',
      category: 'Tree/Graph',
      icon: '🌳',
      difficulty: 'Intermediate',
      shortDescription:
          'Level-order traversal using a queue. Finds shortest paths in unweighted graphs and processes trees level by level.',
      fullDescription:
          'Breadth-First Search (BFS) explores nodes layer by layer, guaranteeing that the shortest path (in terms of edges) to any node is found first. A queue (FIFO) drives the traversal: enqueue the start, then repeatedly dequeue a node, process it, and enqueue its unvisited neighbors.\n\n'
          'For binary trees, BFS produces a level-order traversal. For graphs (grids or adjacency lists), it solves "minimum steps to reach target" problems. Multi-source BFS starts from multiple nodes simultaneously, useful for distance maps (e.g., "distance to nearest gate").',
      keyPatterns: [
        'Level-by-level tree processing (collect nodes per level)',
        'Shortest path in unweighted graph (count BFS layers)',
        'Multi-source BFS (simultaneously flood from multiple starting points)',
        '0-1 BFS with deque for edge weights of 0 or 1',
      ],
      steps: [
        TechniqueStep(
          stepNumber: 1,
          title: 'Initialize the queue and visited set',
          description:
              'Enqueue the starting node(s). Mark them as visited to avoid revisiting.',
        ),
        TechniqueStep(
          stepNumber: 2,
          title: 'Process the current level',
          description:
              'Snapshot the queue length. Dequeue exactly that many nodes — they all belong to the current BFS layer.',
        ),
        TechniqueStep(
          stepNumber: 3,
          title: 'Enqueue neighbors',
          description:
              'For each dequeued node, inspect its children/neighbors. Enqueue those not yet visited and mark them visited.',
        ),
        TechniqueStep(
          stepNumber: 4,
          title: 'Advance to next level',
          description:
              'Increment the level counter after processing all nodes in the current layer. Return the answer when the target is found or the queue is empty.',
        ),
      ],
      codeExamples: [
        CodeExample(
          title: 'Binary Tree Level Order Traversal',
          language: 'python',
          explanation:
              'Returns a list of lists, each inner list containing node values at the same depth.',
          code: '''from collections import deque

class TreeNode:
    def __init__(self, val=0, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right

def levelOrder(root):
    if not root:
        return []
    result = []
    queue = deque([root])
    while queue:
        level_size = len(queue)
        level = []
        for _ in range(level_size):
            node = queue.popleft()
            level.append(node.val)
            if node.left:
                queue.append(node.left)
            if node.right:
                queue.append(node.right)
        result.append(level)
    return result''',
        ),
        CodeExample(
          title: 'Shortest Path in Unweighted Grid',
          language: 'python',
          explanation:
              'BFS on a grid from top-left to bottom-right. Returns the number of steps in the shortest path, or -1 if unreachable.',
          code: '''from collections import deque

def shortestPath(grid):
    rows, cols = len(grid), len(grid[0])
    if grid[0][0] == 1 or grid[rows-1][cols-1] == 1:
        return -1
    queue = deque([(0, 0, 1)])   # (row, col, distance)
    visited = {(0, 0)}
    dirs = [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]
    while queue:
        r, c, dist = queue.popleft()
        if r == rows - 1 and c == cols - 1:
            return dist
        for dr, dc in dirs:
            nr, nc = r + dr, c + dc
            if 0 <= nr < rows and 0 <= nc < cols and grid[nr][nc] == 0 and (nr, nc) not in visited:
                visited.add((nr, nc))
                queue.append((nr, nc, dist + 1))
    return -1''',
        ),
      ],
      timeComplexity: 'O(V + E) where V = vertices, E = edges',
      spaceComplexity: 'O(V) for the queue and visited set',
      tips: [
        'Always mark nodes as visited when they are enqueued, not when dequeued — otherwise duplicates flood the queue.',
        'Snapshot the queue length at the start of each level (level_size = len(queue)) before processing.',
        'For grid problems, define the 4 or 8 directional vectors once and iterate over them.',
        'Multi-source BFS: add all sources to the queue at the start with distance 0.',
      ],
      commonMistakes: [
        'Marking visited when dequeuing (too late) leads to duplicate enqueues and O(n²) behavior.',
        'Not handling the case where start or end is blocked.',
        'Confusing BFS (shortest path) with DFS (exhaustive exploration).',
        'Forgetting to check bounds when exploring grid neighbors.',
      ],
      relatedProblems: [
        'Binary Tree Level Order Traversal',
        'Walls and Gates',
        'Word Ladder',
        'Rotting Oranges',
        'Shortest Path in Binary Matrix',
        'Snakes and Ladders',
      ],
    ),

    // -------------------------------------------------------------------------
    // 5. DFS / Backtracking
    // -------------------------------------------------------------------------
    const Technique(
      id: 'dfs-backtracking',
      name: 'DFS / Backtracking',
      category: 'Tree/Graph',
      icon: '🔀',
      difficulty: 'Intermediate',
      shortDescription:
          'Explore all paths recursively, backtracking when a constraint is violated. Essential for combinatorics and exhaustive search.',
      fullDescription:
          'Backtracking is a refined DFS where, at each decision point, you make a choice, recurse, then undo the choice (backtrack) to try the next option. The key is that you prune branches early — as soon as the current partial solution cannot lead to a valid complete solution, you stop exploring that branch.\n\n'
          'The template: choose → recurse → unchoose. Problems include generating all subsets, permutations, combinations, solving Sudoku/N-Queens, or word search on a grid.',
      keyPatterns: [
        'Subsets: at each element, decide include or exclude',
        'Permutations: choose from remaining unused elements',
        'Combinations: choose k elements from n, maintaining a start index to avoid repeats',
        'Grid DFS: explore 4 directions, mark visited, backtrack by unmarking',
      ],
      steps: [
        TechniqueStep(
          stepNumber: 1,
          title: 'Define the base case',
          description:
              'When have you found a complete solution? (e.g., current path length equals k, or index reached end of input). Add to results and return.',
        ),
        TechniqueStep(
          stepNumber: 2,
          title: 'Iterate over choices',
          description:
              'Loop over all options available at this decision point (remaining elements, grid neighbors, etc.).',
        ),
        TechniqueStep(
          stepNumber: 3,
          title: 'Prune invalid choices',
          description:
              'Before recursing, check if this choice violates any constraint. Skip if so.',
        ),
        TechniqueStep(
          stepNumber: 4,
          title: 'Make the choice and recurse',
          description:
              'Add the choice to the current path and call the recursive function.',
        ),
        TechniqueStep(
          stepNumber: 5,
          title: 'Undo the choice (backtrack)',
          description:
              'After the recursive call returns, remove the last choice from the path so the next iteration starts fresh.',
        ),
      ],
      codeExamples: [
        CodeExample(
          title: 'Generate All Subsets',
          language: 'python',
          explanation:
              'At each index, branch into "include nums[i]" and "exclude nums[i]". Time O(2^n * n) for copying, space O(n) for the call stack.',
          code: '''def subsets(nums):
    result = []

    def backtrack(start, current):
        result.append(list(current))   # every partial path is a valid subset
        for i in range(start, len(nums)):
            current.append(nums[i])
            backtrack(i + 1, current)
            current.pop()              # undo choice

    backtrack(0, [])
    return result''',
        ),
        CodeExample(
          title: 'Permutations',
          language: 'python',
          explanation:
              'Maintain a "used" boolean array. For each position, pick any unused element, mark it used, recurse, then unmark.',
          code: '''def permute(nums):
    result = []
    used = [False] * len(nums)

    def backtrack(current):
        if len(current) == len(nums):
            result.append(list(current))
            return
        for i in range(len(nums)):
            if used[i]:
                continue
            used[i] = True
            current.append(nums[i])
            backtrack(current)
            current.pop()
            used[i] = False

    backtrack([])
    return result''',
        ),
      ],
      timeComplexity: 'O(2^n) for subsets, O(n!) for permutations',
      spaceComplexity: 'O(n) recursion depth',
      tips: [
        'Always undo state changes after the recursive call — this is the "backtrack" step.',
        'Pass a start index to combination problems to avoid generating the same combination in different orders.',
        'Sort the input first when you need to skip duplicates (skip if nums[i] == nums[i-1] and i > start).',
        'For grid backtracking (word search), mark a cell visited before recursing and unmark after.',
      ],
      commonMistakes: [
        'Forgetting to pop from the current path after recursion (most common bug).',
        'Appending a reference to the path instead of a copy: result.append(current) vs result.append(list(current)).',
        'Not advancing the start index in combinations, leading to duplicate results.',
        'Missing the pruning condition, causing exponential blowup on large inputs.',
      ],
      relatedProblems: [
        'Subsets',
        'Permutations',
        'Combination Sum',
        'N-Queens',
        'Word Search',
        'Palindrome Partitioning',
      ],
    ),

    // -------------------------------------------------------------------------
    // 6. Dynamic Programming 1D
    // -------------------------------------------------------------------------
    const Technique(
      id: 'dp-1d',
      name: 'Dynamic Programming 1D',
      category: 'Advanced',
      icon: '📊',
      difficulty: 'Advanced',
      shortDescription:
          'Break a problem into overlapping subproblems, cache results, and build the answer from smaller cases bottom-up.',
      fullDescription:
          'Dynamic Programming (DP) applies when a problem has optimal substructure (the optimal solution contains optimal solutions to its subproblems) and overlapping subproblems (the same subproblems are solved multiple times in a naive recursive approach).\n\n'
          '1D DP uses a single array where dp[i] represents the answer for the first i elements (or up to index i). The recurrence relation links dp[i] to one or more earlier dp[j] values. After filling the table, dp[n] (or the max/min over all dp values) is the answer.',
      keyPatterns: [
        'Linear DP: dp[i] depends on dp[i-1] (Climbing Stairs, House Robber)',
        'Unbounded knapsack: dp[i] can use items repeatedly (Coin Change)',
        '0/1 knapsack: each item used at most once (Subset Sum)',
        'Longest Increasing Subsequence: dp[i] = 1 + max(dp[j]) for j < i, nums[j] < nums[i]',
      ],
      steps: [
        TechniqueStep(
          stepNumber: 1,
          title: 'Define the state',
          description:
              'What does dp[i] represent? Be precise. E.g., "dp[i] = minimum coins to make amount i".',
        ),
        TechniqueStep(
          stepNumber: 2,
          title: 'Identify base cases',
          description:
              'Initialize dp[0] (or dp[1]) with the trivial answer. E.g., dp[0] = 0 (zero coins for amount 0).',
        ),
        TechniqueStep(
          stepNumber: 3,
          title: 'Write the recurrence',
          description:
              'Express dp[i] in terms of dp[i-1], dp[i-2], etc. This is the heart of DP.',
        ),
        TechniqueStep(
          stepNumber: 4,
          title: 'Fill the table',
          description:
              'Iterate i from smallest to largest, computing dp[i] using the recurrence.',
        ),
        TechniqueStep(
          stepNumber: 5,
          title: 'Return the answer',
          description:
              'Return dp[n] or scan dp for the maximum/minimum as required.',
        ),
      ],
      codeExamples: [
        CodeExample(
          title: 'Climbing Stairs',
          language: 'python',
          explanation:
              'dp[i] = number of ways to reach step i. dp[i] = dp[i-1] + dp[i-2]. Optimized to O(1) space with two variables.',
          code: '''def climbStairs(n):
    if n <= 2:
        return n
    a, b = 1, 2   # dp[1], dp[2]
    for _ in range(3, n + 1):
        a, b = b, a + b
    return b''',
        ),
        CodeExample(
          title: 'House Robber',
          language: 'python',
          explanation:
              'dp[i] = max money robbing houses 0..i. Cannot rob two adjacent houses. dp[i] = max(dp[i-1], dp[i-2] + nums[i]).',
          code: '''def rob(nums):
    if not nums:
        return 0
    if len(nums) == 1:
        return nums[0]
    # Space-optimized: only need the previous two values
    prev2 = nums[0]
    prev1 = max(nums[0], nums[1])
    for i in range(2, len(nums)):
        cur = max(prev1, prev2 + nums[i])
        prev2 = prev1
        prev1 = cur
    return prev1''',
        ),
      ],
      timeComplexity: 'O(n)',
      spaceComplexity: 'O(n) for the dp array; often reducible to O(1)',
      tips: [
        'Always think about the state definition first — a clear dp[i] meaning makes the recurrence obvious.',
        'Start with a top-down memoized solution to verify correctness, then optimize to bottom-up.',
        'Space optimization: if dp[i] only depends on dp[i-1] and dp[i-2], use two variables instead of an array.',
        'For problems like Coin Change where the answer is "impossible", initialize with infinity and check at the end.',
      ],
      commonMistakes: [
        'Incorrect base cases — the entire table depends on them being right.',
        'Accessing dp[i-2] when i < 2 (index out of bounds for the first iterations).',
        'Returning dp[n] when the answer is actually max(dp) or another aggregation.',
        'Confusing 0-indexed and 1-indexed dp arrays leading to off-by-one errors.',
      ],
      relatedProblems: [
        'Climbing Stairs',
        'House Robber',
        'Coin Change',
        'Longest Increasing Subsequence',
        'Word Break',
        'Maximum Product Subarray',
      ],
    ),

    // -------------------------------------------------------------------------
    // 7. Dynamic Programming 2D
    // -------------------------------------------------------------------------
    const Technique(
      id: 'dp-2d',
      name: 'Dynamic Programming 2D',
      category: 'Advanced',
      icon: '📐',
      difficulty: 'Advanced',
      shortDescription:
          'dp[i][j] captures the answer for the first i rows and j columns (or for characters i and j of two strings).',
      fullDescription:
          '2D DP extends 1D DP to problems with two varying dimensions — typically a grid (rows × columns) or two strings (of lengths m and n). The table is an (m+1) × (n+1) grid, and each cell is filled using values from cells above, to the left, or diagonally.\n\n'
          'Common problem shapes: grid path counting (Unique Paths), string alignment (Edit Distance, Longest Common Subsequence), interval DP (Burst Balloons), and knapsack with two constraints.',
      keyPatterns: [
        'Grid DP: count paths or find minimum cost through a grid',
        'String DP: LCS, Edit Distance, Interleaving String',
        'Interval DP: dp[i][j] covers subarray nums[i..j] (Matrix Chain Multiplication)',
        'Knapsack with 2D state: items with weight and value constraints',
      ],
      steps: [
        TechniqueStep(
          stepNumber: 1,
          title: 'Define dp[i][j]',
          description:
              'E.g., dp[i][j] = edit distance between word1[:i] and word2[:j], or number of unique paths to cell (i, j).',
        ),
        TechniqueStep(
          stepNumber: 2,
          title: 'Initialize borders',
          description:
              'Fill dp[0][j] and dp[i][0] (the base cases for empty first/second string or the top row/left column of a grid).',
        ),
        TechniqueStep(
          stepNumber: 3,
          title: 'Write the recurrence',
          description:
              'For each cell, derive its value from dp[i-1][j], dp[i][j-1], or dp[i-1][j-1] depending on the problem.',
        ),
        TechniqueStep(
          stepNumber: 4,
          title: 'Fill row by row',
          description:
              'Outer loop over i (rows), inner loop over j (columns). Ensure dependencies are computed before you need them.',
        ),
        TechniqueStep(
          stepNumber: 5,
          title: 'Return dp[m][n]',
          description:
              'The bottom-right cell contains the answer for the full problem.',
        ),
      ],
      codeExamples: [
        CodeExample(
          title: 'Unique Paths',
          language: 'python',
          explanation:
              'dp[i][j] = number of ways to reach cell (i,j) moving only right or down. dp[i][j] = dp[i-1][j] + dp[i][j-1].',
          code: '''def uniquePaths(m, n):
    dp = [[1] * n for _ in range(m)]
    for i in range(1, m):
        for j in range(1, n):
            dp[i][j] = dp[i - 1][j] + dp[i][j - 1]
    return dp[m - 1][n - 1]''',
        ),
        CodeExample(
          title: 'Longest Common Subsequence',
          language: 'python',
          explanation:
              'dp[i][j] = LCS length of text1[:i] and text2[:j]. If chars match, dp[i][j] = dp[i-1][j-1] + 1; else max of the two neighbors.',
          code: '''def longestCommonSubsequence(text1, text2):
    m, n = len(text1), len(text2)
    dp = [[0] * (n + 1) for _ in range(m + 1)]
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if text1[i - 1] == text2[j - 1]:
                dp[i][j] = dp[i - 1][j - 1] + 1
            else:
                dp[i][j] = max(dp[i - 1][j], dp[i][j - 1])
    return dp[m][n]''',
        ),
      ],
      timeComplexity: 'O(m * n)',
      spaceComplexity: 'O(m * n); often reducible to O(min(m, n)) with a rolling array',
      tips: [
        'Use a (m+1) × (n+1) table with a 1-indexed convention to simplify base cases.',
        'Rolling array optimization: if dp[i][j] only depends on the previous row, keep just two rows.',
        'For string problems, the recurrence on matching vs non-matching characters is the key insight.',
        'Draw the table on paper and fill a few cells manually before coding.',
      ],
      commonMistakes: [
        'Forgetting to handle the 0th row/column (empty string/first row border conditions).',
        'Accessing dp[i-1] when i=0 — always initialize borders first.',
        'Wrong loop order — outer loop must cover the dimension whose previous row/column is needed.',
        'Returning dp[m-1][n-1] when the table is 1-indexed (should be dp[m][n]).',
      ],
      relatedProblems: [
        'Unique Paths',
        'Longest Common Subsequence',
        'Edit Distance',
        'Interleaving String',
        'Minimum Path Sum',
        'Maximal Square',
      ],
    ),

    // -------------------------------------------------------------------------
    // 8. Stack
    // -------------------------------------------------------------------------
    const Technique(
      id: 'stack',
      name: 'Stack',
      category: 'Fundamental',
      icon: '📚',
      difficulty: 'Beginner',
      shortDescription:
          'LIFO structure ideal for problems with nested structure, monotonic sequences, or "next greater element" patterns.',
      fullDescription:
          'A stack (Last In, First Out) is the natural structure for problems that require backtracking to the most recently seen state. Classic use cases: matching brackets (the most recently opened must be the next to close), evaluating expressions (maintain an operator stack), and computing next/previous greater elements (monotonic stack).\n\n'
          'A monotonic stack keeps elements in a consistent order (always increasing or always decreasing). When a new element violates the order, you pop until the order is restored — each element is pushed and popped at most once, giving O(n) overall.',
      keyPatterns: [
        'Matching/validation: parentheses, HTML tags',
        'Monotonic decreasing stack: next greater element, daily temperatures',
        'Monotonic increasing stack: largest rectangle in histogram',
        'Expression evaluation: infix/postfix with operator precedence',
      ],
      steps: [
        TechniqueStep(
          stepNumber: 1,
          title: 'Initialize an empty stack',
          description:
              'Use a list as a stack in Python (append = push, pop = pop). For monotonic stacks, decide whether it should be increasing or decreasing.',
        ),
        TechniqueStep(
          stepNumber: 2,
          title: 'Process each element',
          description:
              'For each element, decide whether to push it directly or first pop elements that it "resolves".',
        ),
        TechniqueStep(
          stepNumber: 3,
          title: 'Pop and record answers',
          description:
              'When popping an element, compute the answer for that element (e.g., "the next greater element is the current one that caused the pop").',
        ),
      ],
      codeExamples: [
        CodeExample(
          title: 'Valid Parentheses',
          language: 'python',
          explanation:
              'Push opening brackets. On closing bracket, check the top matches; if not, invalid. Valid if stack is empty at the end.',
          code: '''def isValid(s):
    stack = []
    mapping = {")": "(", "}": "{", "]": "["}
    for c in s:
        if c in mapping:
            top = stack.pop() if stack else "#"
            if mapping[c] != top:
                return False
        else:
            stack.append(c)
    return len(stack) == 0''',
        ),
        CodeExample(
          title: 'Next Greater Element (monotonic stack)',
          language: 'python',
          explanation:
              'Maintain a decreasing stack of indices. When nums[i] > nums[stack top], pop and record that the next greater for the popped index is nums[i].',
          code: '''def nextGreaterElement(nums):
    n = len(nums)
    result = [-1] * n
    stack = []   # monotonic decreasing stack of indices
    for i in range(n):
        while stack and nums[stack[-1]] < nums[i]:
            idx = stack.pop()
            result[idx] = nums[i]
        stack.append(i)
    return result''',
        ),
      ],
      timeComplexity: 'O(n) — each element is pushed and popped at most once',
      spaceComplexity: 'O(n)',
      tips: [
        'For monotonic stacks, ask: should the stack be increasing or decreasing? It depends on whether you want next greater or next smaller.',
        'Sentinel values (appending 0 at both ends of height array) simplify edge cases in histogram problems.',
        'When storing indices instead of values in the stack, you can compute widths/distances during pops.',
        'Python\'s list uses append/pop([-1]) for O(1) stack operations.',
      ],
      commonMistakes: [
        'Checking stack[-1] without verifying the stack is non-empty first.',
        'Building a monotonic stack with the wrong ordering (increasing vs decreasing).',
        'Forgetting to process remaining elements in the stack after the main loop.',
        'Using a deque when a simple list suffices — adds unnecessary complexity.',
      ],
      relatedProblems: [
        'Valid Parentheses',
        'Daily Temperatures',
        'Largest Rectangle in Histogram',
        'Min Stack',
        'Next Greater Element I',
        'Decode String',
      ],
    ),

    // -------------------------------------------------------------------------
    // 9. Heap / Priority Queue
    // -------------------------------------------------------------------------
    const Technique(
      id: 'heap',
      name: 'Heap / Priority Queue',
      category: 'Advanced',
      icon: '⛰️',
      difficulty: 'Intermediate',
      shortDescription:
          'Efficiently access the min or max element. Use for K-th largest, top-K elements, merge K sorted lists, and scheduling.',
      fullDescription:
          'A heap is a complete binary tree satisfying the heap property: in a min-heap, every parent is ≤ its children, so the root is always the minimum. Python\'s heapq module provides a min-heap. To simulate a max-heap, negate values before inserting and negate again when extracting.\n\n'
          'The heap supports O(log n) push and pop, and O(1) peek at the min (or max). This makes it ideal for streaming problems where you process elements one at a time but need quick access to the current k-th largest, or for merging k sorted streams.',
      keyPatterns: [
        'Top-K elements: maintain a min-heap of size k',
        'K-way merge: always pop the smallest head across k sorted lists',
        'Median of a stream: two heaps (max-heap for lower half, min-heap for upper half)',
        'Dijkstra\'s algorithm: min-heap keyed on distance',
      ],
      steps: [
        TechniqueStep(
          stepNumber: 1,
          title: 'Choose heap type',
          description:
              'Min-heap for "find smallest" problems; max-heap (negated values) for "find largest". Python heapq is always a min-heap.',
        ),
        TechniqueStep(
          stepNumber: 2,
          title: 'Push elements with priority',
          description:
              'Push tuples (priority, value) so heapq breaks ties consistently. For max-heap, push (-value, value).',
        ),
        TechniqueStep(
          stepNumber: 3,
          title: 'Pop and process',
          description:
              'heapq.heappop returns the smallest element. For top-K, pop when heap exceeds size k to evict the smallest seen so far.',
        ),
        TechniqueStep(
          stepNumber: 4,
          title: 'Use heapq.heapify for bulk initialization',
          description:
              'heapify converts a list to a heap in O(n) — faster than n individual pushes.',
        ),
      ],
      codeExamples: [
        CodeExample(
          title: 'K Largest Elements in an Array',
          language: 'python',
          explanation:
              'Keep a min-heap of size k. When size exceeds k, pop the smallest. After processing all elements, the heap contains the k largest.',
          code: '''import heapq

def kLargest(nums, k):
    heap = []
    for num in nums:
        heapq.heappush(heap, num)
        if len(heap) > k:
            heapq.heappop(heap)   # evict the smallest; keep k largest
    return sorted(heap, reverse=True)''',
        ),
        CodeExample(
          title: 'Merge K Sorted Lists',
          language: 'python',
          explanation:
              'Push the head of each list as (value, list_index, node) into a min-heap. Pop the smallest, push its successor. O(N log k).',
          code: '''import heapq

class ListNode:
    def __init__(self, val=0, next=None):
        self.val = val
        self.next = next

def mergeKLists(lists):
    heap = []
    for i, node in enumerate(lists):
        if node:
            heapq.heappush(heap, (node.val, i, node))

    dummy = ListNode(0)
    cur = dummy
    while heap:
        val, i, node = heapq.heappop(heap)
        cur.next = node
        cur = cur.next
        if node.next:
            heapq.heappush(heap, (node.next.val, i, node.next))
    return dummy.next''',
        ),
      ],
      timeComplexity: 'O(n log k) for top-K; O(N log k) for K-way merge',
      spaceComplexity: 'O(k)',
      tips: [
        'Python heapq is a min-heap. For max-heap behavior, negate the key: push(-val) and negate when popping.',
        'Push tuples (priority, value) to break ties and avoid comparison errors with complex objects.',
        'heapq.nlargest(k, nums) and heapq.nsmallest(k, nums) are convenient but internally do the same thing.',
        'For the "median of stream" problem, balance the two heaps so |lo| - |hi| <= 1 at all times.',
      ],
      commonMistakes: [
        'Comparing non-comparable objects in the heap — always wrap in a tuple with a numeric priority.',
        'Using a max-heap by accident (forgetting to negate, or thinking heapq is a max-heap).',
        'Not handling empty heaps before calling heappop.',
        'Unnecessary O(n log n) sort when a O(n log k) heap solution is expected.',
      ],
      relatedProblems: [
        'Kth Largest Element in an Array',
        'Merge K Sorted Lists',
        'Find Median from Data Stream',
        'Task Scheduler',
        'Top K Frequent Elements',
        'K Closest Points to Origin',
      ],
    ),

    // -------------------------------------------------------------------------
    // 10. Hash Map / Set
    // -------------------------------------------------------------------------
    const Technique(
      id: 'hashmap',
      name: 'Hash Map / Set',
      category: 'Fundamental',
      icon: '#️⃣',
      difficulty: 'Beginner',
      shortDescription:
          'O(1) average lookup and insert. Trade extra space for time to avoid O(n) scans.',
      fullDescription:
          'Hash maps (dictionaries in Python) and hash sets provide O(1) average-case insert, lookup, and delete. They are the go-to tool for trading space for time: instead of scanning an array for a complement or tracking previous elements, store them in a hash structure.\n\n'
          'Common applications: frequency counting (Counter), complement lookup (Two Sum), grouping elements by a key (Group Anagrams), and membership testing (seen-before tracking). Collections.Counter, defaultdict, and set cover most interview use cases.',
      keyPatterns: [
        'Complement lookup: for each element, check if target - element is in the map',
        'Frequency counting: count occurrences with Counter or a dict',
        'Grouping: use a computed key (e.g., sorted tuple) to bucket elements',
        'Seen-before tracking: maintain a set of visited states',
      ],
      steps: [
        TechniqueStep(
          stepNumber: 1,
          title: 'Choose the right structure',
          description:
              'Use a dict when you need to map key → value (e.g., value → index). Use a set when you only need membership testing.',
        ),
        TechniqueStep(
          stepNumber: 2,
          title: 'Populate during the first pass',
          description:
              'Insert elements (or their computed keys) as you iterate. For Two Sum, insert value → index.',
        ),
        TechniqueStep(
          stepNumber: 3,
          title: 'Query in the same or second pass',
          description:
              'For each element, compute the "key you are looking for" and check the hash structure in O(1).',
        ),
      ],
      codeExamples: [
        CodeExample(
          title: 'Two Sum',
          language: 'python',
          explanation:
              'For each number, check if its complement (target - num) is already stored. One pass, O(n) time.',
          code: '''def twoSum(nums, target):
    seen = {}   # value -> index
    for i, num in enumerate(nums):
        complement = target - num
        if complement in seen:
            return [seen[complement], i]
        seen[num] = i
    return []''',
        ),
        CodeExample(
          title: 'Group Anagrams',
          language: 'python',
          explanation:
              'Sort each word to produce its canonical "anagram key". Group words sharing the same key using a defaultdict.',
          code: '''from collections import defaultdict

def groupAnagrams(strs):
    groups = defaultdict(list)
    for word in strs:
        key = tuple(sorted(word))   # canonical form
        groups[key].append(word)
    return list(groups.values())''',
        ),
      ],
      timeComplexity: 'O(n) — single pass with O(1) hash operations',
      spaceComplexity: 'O(n)',
      tips: [
        'Python\'s collections.Counter is perfect for frequency counting — supports arithmetic and most_common(k).',
        'Use defaultdict(list) to avoid KeyError when grouping.',
        'Sets are faster than lists for membership testing: "x in some_set" is O(1) vs O(n) for a list.',
        'For problems requiring ordered insertion order, Python dicts (3.7+) preserve insertion order.',
      ],
      commonMistakes: [
        'Using a list for membership testing (O(n) per check) when a set would give O(1).',
        'Returning the wrong index pair order — the complement\'s index comes first if found before current.',
        'Modifying a dict while iterating over it.',
        'Hashing unhashable types like lists — use tuples as keys instead.',
      ],
      relatedProblems: [
        'Two Sum',
        'Group Anagrams',
        'Top K Frequent Elements',
        'Contains Duplicate',
        'Longest Consecutive Sequence',
        'Valid Sudoku',
      ],
    ),

    // -------------------------------------------------------------------------
    // 11. Linked List
    // -------------------------------------------------------------------------
    const Technique(
      id: 'linked-list',
      name: 'Linked List',
      category: 'Fundamental',
      icon: '🔗',
      difficulty: 'Beginner',
      shortDescription:
          'Fast/slow pointers for cycle detection, reverse in-place, dummy head for cleaner edge cases.',
      fullDescription:
          'Linked list problems rarely require clever algorithms — they test pointer manipulation. The key tricks are: (1) dummy head node to handle edge cases at the beginning uniformly; (2) fast/slow pointers for cycle detection (Floyd\'s algorithm) and finding the middle; (3) in-place reversal by re-linking nodes; (4) two-pointer with offset to find the k-th node from the end.\n\n'
          'Because linked lists have no random access, many array-style tricks don\'t apply directly. Instead, think about what pointer you need to maintain to perform the operation in one pass.',
      keyPatterns: [
        'Dummy head: simplifies insertions/deletions at the front',
        'Fast/slow pointers: cycle detection, middle node, k-th from end',
        'In-place reverse: iterative prev/cur/next pointer manipulation',
        'Merge: merge two sorted lists or k sorted lists',
      ],
      steps: [
        TechniqueStep(
          stepNumber: 1,
          title: 'Create a dummy head (when needed)',
          description:
              'dummy = ListNode(0); dummy.next = head. Return dummy.next at the end. Eliminates special-casing an empty list or head deletion.',
        ),
        TechniqueStep(
          stepNumber: 2,
          title: 'Initialize pointers',
          description:
              'For reversal: prev = None, cur = head. For fast/slow: slow = fast = head. For k-th from end: use two pointers offset by k.',
        ),
        TechniqueStep(
          stepNumber: 3,
          title: 'Traverse and manipulate',
          description:
              'Save next = cur.next before breaking a link. This is critical — once you set cur.next = prev, the original next is lost without this save.',
        ),
        TechniqueStep(
          stepNumber: 4,
          title: 'Reconnect and return',
          description:
              'After manipulation, ensure all nodes are properly linked. Return the new head (prev after reversal, dummy.next after insertions).',
        ),
      ],
      codeExamples: [
        CodeExample(
          title: 'Detect Cycle (Floyd\'s Tortoise and Hare)',
          language: 'python',
          explanation:
              'If a cycle exists, fast and slow pointers meet inside it. Phase 2 finds the cycle start.',
          code: '''def hasCycle(head):
    slow = fast = head
    # Phase 1: detect cycle
    while fast and fast.next:
        slow = slow.next
        fast = fast.next.next
        if slow is fast:
            return True
    return False

def detectCycleStart(head):
    slow = fast = head
    # Phase 1: find meeting point
    while fast and fast.next:
        slow = slow.next
        fast = fast.next.next
        if slow is fast:
            break
    else:
        return None  # no cycle
    # Phase 2: move slow to head; advance both at same speed
    slow = head
    while slow is not fast:
        slow = slow.next
        fast = fast.next
    return slow  # cycle start''',
        ),
        CodeExample(
          title: 'Reverse Linked List (iterative)',
          language: 'python',
          explanation:
              'Iteratively re-links each node to point to the previous one. Always save next before breaking the link.',
          code: '''def reverseList(head):
    prev = None
    cur = head
    while cur:
        nxt = cur.next   # save before breaking
        cur.next = prev  # reverse the link
        prev = cur       # advance prev
        cur = nxt        # advance cur
    return prev   # new head''',
        ),
      ],
      timeComplexity: 'O(n)',
      spaceComplexity: 'O(1) for iterative approaches',
      tips: [
        'Always save nxt = cur.next before re-linking — the most common linked list bug is forgetting this.',
        'Dummy head node makes deletion logic uniform (no special case for deleting the head).',
        'To find the middle, stop when fast reaches the end (while fast and fast.next).',
        'For k-th from end: advance one pointer k steps ahead, then move both at the same speed.',
      ],
      commonMistakes: [
        'Not saving the next pointer before modifying cur.next (leads to lost nodes).',
        'Returning cur instead of prev after reversal (cur is null at the end of the loop).',
        'Off-by-one in fast/slow pointer: fast and fast.next must both be non-null before fast.next.next.',
        'Not handling an empty list or a single-node list at the start.',
      ],
      relatedProblems: [
        'Linked List Cycle',
        'Linked List Cycle II',
        'Reverse Linked List',
        'Merge Two Sorted Lists',
        'Remove Nth Node From End',
        'LRU Cache',
      ],
    ),

    // -------------------------------------------------------------------------
    // 12. Greedy
    // -------------------------------------------------------------------------
    const Technique(
      id: 'greedy',
      name: 'Greedy',
      category: 'Optimization',
      icon: '💰',
      difficulty: 'Intermediate',
      shortDescription:
          'Make the locally optimal choice at each step. Works when the greedy choice property holds — local optima lead to a global optimum.',
      fullDescription:
          'A greedy algorithm builds a solution piece by piece, always choosing the next piece that offers the most immediate benefit. Unlike DP, it never backtracks. Greedy works when the problem has the greedy choice property: a globally optimal solution can be constructed by making locally optimal choices.\n\n'
          'Common scenarios: interval scheduling (select non-overlapping intervals by earliest end time), jump game (track the farthest reachable index), fractional knapsack, and Huffman encoding. The key is proving — or recognizing — that greedy does not miss a better solution.',
      keyPatterns: [
        'Interval scheduling: sort by end time, greedily select non-overlapping',
        'Jump game: track the maximum reachable index as you scan left to right',
        'Activity selection: equivalent to interval scheduling',
        'Assign tasks to minimize makespan: sort and assign optimally',
      ],
      steps: [
        TechniqueStep(
          stepNumber: 1,
          title: 'Identify the greedy criterion',
          description:
              'What property should you sort or prioritize by? For intervals it\'s end time; for tasks it might be processing time or deadline.',
        ),
        TechniqueStep(
          stepNumber: 2,
          title: 'Sort (or use a priority queue)',
          description:
              'Sort the input by the greedy criterion. This preprocessing step is often O(n log n) and is the dominant cost.',
        ),
        TechniqueStep(
          stepNumber: 3,
          title: 'Greedily make choices',
          description:
              'Iterate through the sorted input, making the locally optimal choice at each step without reconsidering past decisions.',
        ),
      ],
      codeExamples: [
        CodeExample(
          title: 'Jump Game',
          language: 'python',
          explanation:
              'Track the farthest index reachable from any position visited so far. If the current index exceeds that, we cannot proceed.',
          code: '''def canJump(nums):
    farthest = 0
    for i, jump in enumerate(nums):
        if i > farthest:
            return False   # can't reach index i
        farthest = max(farthest, i + jump)
    return True

def jumpGameII(nums):
    """Minimum jumps to reach the last index."""
    jumps = 0
    cur_end = 0    # farthest we can reach with current number of jumps
    cur_farthest = 0
    for i in range(len(nums) - 1):
        cur_farthest = max(cur_farthest, i + nums[i])
        if i == cur_end:
            jumps += 1
            cur_end = cur_farthest
    return jumps''',
        ),
        CodeExample(
          title: 'Non-overlapping Intervals (interval scheduling)',
          language: 'python',
          explanation:
              'Sort by end time. Greedily keep intervals; if a new interval overlaps with the last kept, remove the one with the later end time (which is the new interval since they are sorted).',
          code: '''def eraseOverlapIntervals(intervals):
    if not intervals:
        return 0
    intervals.sort(key=lambda x: x[1])   # sort by end time
    removed = 0
    prev_end = intervals[0][1]
    for start, end in intervals[1:]:
        if start < prev_end:
            # Overlap: remove the interval with the later end (current one)
            removed += 1
        else:
            prev_end = end
    return removed''',
        ),
      ],
      timeComplexity: 'O(n log n) dominated by sorting',
      spaceComplexity: 'O(1) after sorting',
      tips: [
        'Always think: can I prove a greedy choice never leads to a worse solution? If not, DP might be needed.',
        'Interval problems almost always sort by start or end time — try both if the first doesn\'t work.',
        'For jump game variants, tracking the "boundary" of the current jump level is the key insight.',
        'Exchange argument: show that swapping any adjacent greedy choice with a non-greedy one cannot improve the solution.',
      ],
      commonMistakes: [
        'Applying greedy to a problem that requires DP (e.g., 0/1 knapsack cannot be solved greedily).',
        'Sorting by the wrong key (e.g., sorting interval scheduling by start time instead of end time).',
        'Not handling ties in the sort key — they can lead to incorrect greedy selections.',
        'Forgetting to update the "last selected" state after a greedy pick.',
      ],
      relatedProblems: [
        'Jump Game',
        'Jump Game II',
        'Non-overlapping Intervals',
        'Merge Intervals',
        'Gas Station',
        'Candy',
      ],
    ),

    // -------------------------------------------------------------------------
    // 13. Trie (Prefix Tree)
    // -------------------------------------------------------------------------
    const Technique(
      id: 'trie',
      name: 'Trie (Prefix Tree)',
      category: 'Advanced',
      icon: '🌳',
      difficulty: 'Intermediate',
      shortDescription:
          'A tree data structure for storing strings where each node represents a character. Enables O(L) prefix lookups.',
      fullDescription:
          'A Trie (pronounced "try") is a tree-shaped data structure optimized for storing and searching strings. Each node represents a single character, and paths from the root to a node represent prefixes. This makes Tries ideal for autocomplete, spell-check, and IP routing.\n\n'
          'Each node contains a map of child characters and a boolean flag marking whether it is the end of a valid word. Insertion and search are both O(L) where L is the string length — independent of the number of stored strings.',
      keyPatterns: [
        'Autocomplete / prefix search',
        'Word dictionary lookup',
        'IP routing tables',
        'Word games (Boggle, crossword solvers)',
      ],
      steps: [
        TechniqueStep(
          stepNumber: 1,
          title: 'Define TrieNode',
          description: 'Each node holds a dict/array of children (one per character) and a boolean `is_end` flag.',
        ),
        TechniqueStep(
          stepNumber: 2,
          title: 'Insert a word',
          description: 'Iterate through each character. If no child exists for it, create one. After the last character, mark `is_end = True`.',
        ),
        TechniqueStep(
          stepNumber: 3,
          title: 'Search or startsWith',
          description: 'Walk down the Trie following each character. If any character is missing, return False. For `search`, also check `is_end`.',
        ),
      ],
      codeExamples: [
        CodeExample(
          title: 'Trie — Insert, Search, StartsWith',
          language: 'python',
          explanation: 'Classic Trie implementation with insert, search, and prefix check in O(L) time.',
          code: '''class TrieNode:
    def __init__(self):
        self.children = {}
        self.is_end = False

class Trie:
    def __init__(self):
        self.root = TrieNode()

    def insert(self, word: str) -> None:
        node = self.root
        for ch in word:
            if ch not in node.children:
                node.children[ch] = TrieNode()
            node = node.children[ch]
        node.is_end = True

    def search(self, word: str) -> bool:
        node = self.root
        for ch in word:
            if ch not in node.children:
                return False
            node = node.children[ch]
        return node.is_end

    def startsWith(self, prefix: str) -> bool:
        node = self.root
        for ch in prefix:
            if ch not in node.children:
                return False
            node = node.children[ch]
        return True''',
        ),
        CodeExample(
          title: 'Word Search II using Trie',
          language: 'python',
          explanation: 'Find all words from a dictionary that exist in a 2D board. Build a Trie then DFS the board.',
          code: '''def findWords(board, words):
    root = TrieNode()
    for w in words:
        node = root
        for c in w:
            node = node.children.setdefault(c, TrieNode())
        node.is_end = True

    rows, cols = len(board), len(board[0])
    result = set()

    def dfs(node, r, c, path):
        ch = board[r][c]
        if ch not in node.children:
            return
        nxt = node.children[ch]
        path += ch
        if nxt.is_end:
            result.add(path)
        board[r][c] = "#"   # mark visited
        for dr, dc in [(1,0),(-1,0),(0,1),(0,-1)]:
            nr, nc = r+dr, c+dc
            if 0 <= nr < rows and 0 <= nc < cols and board[nr][nc] != "#":
                dfs(nxt, nr, nc, path)
        board[r][c] = ch   # restore

    for r in range(rows):
        for c in range(cols):
            dfs(root, r, c, "")
    return list(result)''',
        ),
      ],
      relatedProblems: [
        'Implement Trie (Prefix Tree)',
        'Word Search II',
        'Design Add and Search Words Data Structure',
        'Replace Words',
        'Longest Word in Dictionary',
      ],
      tips: [
        'Use a dict for children — handles arbitrary character sets',
        'Trie beats hash sets when you need prefix queries',
        'For space optimization, use compressed Trie (Radix Tree)',
        'Combine DFS with Trie for board word-search problems',
      ],
      commonMistakes: [
        'Forgetting to set is_end=True after inserting the last character',
        'Confusing search (full word) with startsWith (prefix)',
        'Not restoring board cells after DFS backtrack',
        'Using a list of 26 instead of a dict — wastes memory for sparse data',
      ],
      timeComplexity: 'O(L)',
      spaceComplexity: 'O(L × N)',
    ),

    // -------------------------------------------------------------------------
    // 14. Union-Find (Disjoint Set)
    // -------------------------------------------------------------------------
    const Technique(
      id: 'union-find',
      name: 'Union-Find',
      category: 'Advanced',
      icon: '🔗',
      difficulty: 'Intermediate',
      shortDescription:
          'Efficiently track connected components with near O(1) union and find operations using path compression and union by rank.',
      fullDescription:
          'Union-Find (also called Disjoint Set Union or DSU) is a data structure that maintains a partition of a set of elements into disjoint groups. It supports two core operations: **Find** (which group does element X belong to?) and **Union** (merge the groups of X and Y).\n\n'
          'With **path compression** (flattening the tree on each Find) and **union by rank** (always attaching the smaller tree under the larger), both operations run in nearly O(1) amortized time — specifically O(α(n)) where α is the inverse Ackermann function, essentially a constant for all practical inputs.',
      keyPatterns: [
        'Detecting cycles in undirected graphs',
        'Counting connected components',
        'Kruskal\'s Minimum Spanning Tree',
        'Dynamic connectivity queries',
      ],
      steps: [
        TechniqueStep(
          stepNumber: 1,
          title: 'Initialize',
          description: 'Create parent[] and rank[] arrays. Each element is its own parent (parent[i] = i), rank = 0.',
        ),
        TechniqueStep(
          stepNumber: 2,
          title: 'Find with path compression',
          description: 'Recursively find the root. On the way back up, set parent[x] = root directly (path compression).',
        ),
        TechniqueStep(
          stepNumber: 3,
          title: 'Union by rank',
          description: 'Find both roots. If different, attach the lower-rank tree under the higher-rank one. Increment rank if they were equal.',
        ),
      ],
      codeExamples: [
        CodeExample(
          title: 'Union-Find with path compression + union by rank',
          language: 'python',
          explanation: 'Full DSU implementation. find() is nearly O(1) amortized thanks to path compression.',
          code: '''class UnionFind:
    def __init__(self, n):
        self.parent = list(range(n))
        self.rank = [0] * n
        self.components = n

    def find(self, x):
        if self.parent[x] != x:
            self.parent[x] = self.find(self.parent[x])  # path compression
        return self.parent[x]

    def union(self, x, y):
        px, py = self.find(x), self.find(y)
        if px == py:
            return False  # already connected
        if self.rank[px] < self.rank[py]:
            px, py = py, px
        self.parent[py] = px
        if self.rank[px] == self.rank[py]:
            self.rank[px] += 1
        self.components -= 1
        return True

    def connected(self, x, y):
        return self.find(x) == self.find(y)''',
        ),
        CodeExample(
          title: 'Count connected components in a graph',
          language: 'python',
          explanation: 'Union all edges, then count distinct roots. Classic Union-Find application.',
          code: '''def countComponents(n, edges):
    uf = UnionFind(n)
    for u, v in edges:
        uf.union(u, v)
    return uf.components

# Example: n=5, edges=[[0,1],[1,2],[3,4]]
# Components: {0,1,2} and {3,4} → answer = 2''',
        ),
      ],
      relatedProblems: [
        'Number of Connected Components in an Undirected Graph',
        'Redundant Connection',
        'Accounts Merge',
        'Graph Valid Tree',
        'Making a Large Island',
      ],
      tips: [
        'Always use both path compression AND union by rank for best performance',
        'Track a component count — decrement on each successful union',
        'For grid problems, map (r,c) to r*cols+c as the node index',
        'Use union-find for offline connectivity (all edges known upfront)',
      ],
      commonMistakes: [
        'Forgetting path compression makes subsequent finds slower',
        'Unioning by index rather than by rank can degrade to O(n)',
        'Not decrementing component count after a successful union',
        'Using union-find for directed graphs (only works for undirected)',
      ],
      timeComplexity: 'O(α(n)) ≈ O(1)',
      spaceComplexity: 'O(n)',
    ),

    // -------------------------------------------------------------------------
    // 15. Monotonic Stack / Queue
    // -------------------------------------------------------------------------
    const Technique(
      id: 'monotonic-stack',
      name: 'Monotonic Stack',
      category: 'Advanced',
      icon: '📊',
      difficulty: 'Intermediate',
      shortDescription:
          'Maintain a stack whose elements are always in sorted order to answer "next greater/smaller element" queries in O(n).',
      fullDescription:
          'A Monotonic Stack is a stack that maintains elements in strictly increasing or decreasing order. When a new element violates the monotonic property, you pop elements from the stack until the property is restored — processing those popped elements in the process.\n\n'
          'This pattern solves "next greater element", "previous smaller element", and histogram-area problems in O(n) time, replacing naive O(n²) brute-force approaches. A **Monotonic Deque** extends this idea to a sliding-window maximum/minimum query in O(n).',
      keyPatterns: [
        'Next Greater / Next Smaller element for each index',
        'Largest rectangle in histogram',
        'Sliding window maximum (monotonic deque)',
        'Stock span / temperature waiting days',
      ],
      steps: [
        TechniqueStep(
          stepNumber: 1,
          title: 'Choose monotonic direction',
          description: 'Decreasing stack → find next greater element. Increasing stack → find next smaller element.',
        ),
        TechniqueStep(
          stepNumber: 2,
          title: 'Iterate and pop',
          description: 'For each element, while the stack is not empty AND the top violates the monotonic property, pop and process. The current element is the "answer" for the popped element.',
        ),
        TechniqueStep(
          stepNumber: 3,
          title: 'Push and continue',
          description: 'Push the current element (or its index) onto the stack. Anything remaining in the stack at the end has no valid answer (use -1 or 0).',
        ),
      ],
      codeExamples: [
        CodeExample(
          title: 'Next Greater Element',
          language: 'python',
          explanation: 'For each element, find the next element to the right that is strictly greater. Uses a monotonic decreasing stack of indices.',
          code: '''def nextGreaterElement(nums):
    n = len(nums)
    result = [-1] * n
    stack = []   # indices, decreasing by value

    for i in range(n):
        # current num is greater than stack top → pop & assign
        while stack and nums[stack[-1]] < nums[i]:
            idx = stack.pop()
            result[idx] = nums[i]
        stack.append(i)
    # remaining indices have no greater element → result stays -1
    return result

# nums = [2, 1, 2, 4, 3]
# result = [4, 2, 4, -1, -1]''',
        ),
        CodeExample(
          title: 'Largest Rectangle in Histogram',
          language: 'python',
          explanation: 'Classic monotonic stack problem. Maintain increasing stack of bar indices. Pop when a shorter bar is found and compute max area.',
          code: '''def largestRectangleArea(heights):
    stack = []  # increasing stack of indices
    max_area = 0
    heights = heights + [0]  # sentinel to flush all remaining

    for i, h in enumerate(heights):
        start = i
        while stack and heights[stack[-1]] > h:
            idx = stack.pop()
            width = i - (stack[-1] + 1 if stack else 0)
            max_area = max(max_area, heights[idx] * width)
        stack.append(i)
    return max_area

# heights = [2, 1, 5, 6, 2, 3] → 10''',
        ),
      ],
      relatedProblems: [
        'Daily Temperatures',
        'Largest Rectangle in Histogram',
        'Sliding Window Maximum',
        'Trapping Rain Water',
        'Sum of Subarray Minimums',
        'Stock Price Span',
      ],
      tips: [
        'Store indices on the stack (not values) to calculate widths/spans',
        'Add a sentinel value (0 or -∞) to automatically flush the stack at the end',
        'For circular arrays, iterate 2n and use index % n',
        'Monotonic deque = same idea but also evict old indices from the front',
      ],
      commonMistakes: [
        'Storing values instead of indices — you lose position information for width calculation',
        'Forgetting to handle elements that remain in the stack after the loop',
        'Using a max-stack when you need a min-stack (or vice versa)',
        'Not adding a sentinel for histogram problems — last bars never get processed',
      ],
      timeComplexity: 'O(n)',
      spaceComplexity: 'O(n)',
    ),
  ];

  // ---------------------------------------------------------------------------
  // Static helpers
  // ---------------------------------------------------------------------------

  static List<Technique> getByCategory(String category) {
    return techniques.where((t) => t.category == category).toList();
  }

  static Technique? getById(String id) {
    try {
      return techniques.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
