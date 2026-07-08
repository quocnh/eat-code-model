import '../models/quiz_question.dart';

/// 3 MCQ questions per technique ID.
/// Passing threshold: ≥ 2 / 3 correct.
class QuizData {
  static const Map<String, List<QuizQuestion>> questions = {
    // ── Hash Map / Set ──────────────────────────────────────────────────────
    'hashmap': [
      QuizQuestion(
        question: 'What is the average time complexity for lookup in a Hash Map?',
        options: ['O(1)', 'O(log n)', 'O(n)', 'O(n²)'],
        correctIndex: 0,
        explanation: 'Hash Maps use a hash function to compute the bucket index directly, giving O(1) average-case lookup.',
      ),
      QuizQuestion(
        question: 'Which problem pattern is best solved with a Hash Map?',
        options: [
          'Two Sum — find a pair with a target sum',
          'Binary search on a sorted array',
          'Level-order tree traversal',
          'Merge sort of a linked list',
        ],
        correctIndex: 0,
        explanation: 'Two Sum stores each number in a map to look up its complement in O(1), making the overall solution O(n).',
      ),
      QuizQuestion(
        question: 'When using a HashSet, what property is guaranteed?',
        options: [
          'Elements are stored in sorted order',
          'Each element is unique',
          'Elements can be accessed by index',
          'Elements are maintained in insertion order',
        ],
        correctIndex: 1,
        explanation: 'A HashSet never stores duplicate values — every element appears at most once.',
      ),
    ],

    // ── Two Pointers ────────────────────────────────────────────────────────
    'two-pointers': [
      QuizQuestion(
        question: 'Two Pointers most commonly requires the input array to be...',
        options: ['Sorted (usually)', 'Of even length', 'Containing only positive integers', 'Already partitioned'],
        correctIndex: 0,
        explanation: 'The sorted property allows the two pointers to converge toward a target by shifting left or right based on the current sum.',
      ),
      QuizQuestion(
        question: 'Time complexity of Two Sum on a sorted array using two pointers?',
        options: ['O(n²)', 'O(n log n)', 'O(n)', 'O(1)'],
        correctIndex: 2,
        explanation: 'Each pointer moves at most n steps total, giving a linear O(n) solution.',
      ),
      QuizQuestion(
        question: 'Two Pointers is most useful when...',
        options: [
          'Finding a pair/triplet satisfying a condition in a sorted array',
          'Counting inversions in an array',
          'Building a prefix-sum array',
          'Checking if a number is prime',
        ],
        correctIndex: 0,
        explanation: 'Two pointers shine when a sorted input allows you to shrink the search space by adjusting pointers based on the current comparison.',
      ),
    ],

    // ── Sliding Window ───────────────────────────────────────────────────────
    'sliding-window': [
      QuizQuestion(
        question: 'Sliding Window is used to efficiently find...',
        options: [
          'A contiguous subarray satisfying a condition',
          'The minimum element in a rotated sorted array',
          'The longest common subsequence of two strings',
          'The shortest path in a weighted graph',
        ],
        correctIndex: 0,
        explanation: 'By expanding and shrinking a window over a contiguous range, you avoid redundant recomputation — reducing O(n²) to O(n).',
      ),
      QuizQuestion(
        question: 'Time complexity of Sliding Window for "Longest Substring Without Repeating Characters"?',
        options: ['O(n²)', 'O(n)', 'O(n log n)', 'O(n × k)'],
        correctIndex: 1,
        explanation: 'Each character is added and removed from the window at most once, giving O(n) overall.',
      ),
      QuizQuestion(
        question: 'A fixed window of size k over n elements produces how many windows?',
        options: ['k', 'n / k', 'n − k + 1', 'n − k'],
        correctIndex: 2,
        explanation: 'The window starts at index 0 and ends when its right edge reaches index n−1, giving n−k+1 positions.',
      ),
    ],

    // ── Monotonic Stack ──────────────────────────────────────────────────────
    'monotonic-stack': [
      QuizQuestion(
        question: 'A monotonic stack maintains elements in...',
        options: [
          'Random order',
          'Strictly increasing or strictly decreasing order',
          'The last k elements inserted',
          'Only unique elements',
        ],
        correctIndex: 1,
        explanation: 'Before pushing, elements that violate the monotonicity are popped — maintaining a sorted invariant throughout.',
      ),
      QuizQuestion(
        question: 'Which problem is classically solved with a monotonic stack?',
        options: [
          'Next Greater Element',
          'Binary search on sorted array',
          'Shortest path in a graph',
          'Longest common subsequence',
        ],
        correctIndex: 0,
        explanation: 'A monotonically decreasing stack lets you resolve the "next greater element" for each item the moment you pop it.',
      ),
      QuizQuestion(
        question: 'Time complexity for finding the next greater element for all n elements?',
        options: ['O(n²)', 'O(n log n)', 'O(n)', 'O(1)'],
        correctIndex: 2,
        explanation: 'Each element is pushed and popped from the stack at most once, making the total work O(n).',
      ),
    ],

    // ── Binary Search ────────────────────────────────────────────────────────
    'binary-search': [
      QuizQuestion(
        question: 'Binary Search requires the input to be...',
        options: ['Unsorted', 'Sorted ✓', 'Circular', 'Two-dimensional'],
        correctIndex: 1,
        explanation: 'Binary search halves the search space by comparing the target to the middle element — this only works when elements are sorted.',
      ),
      QuizQuestion(
        question: 'Binary Search on n elements has time complexity of...',
        options: ['O(n)', 'O(n log n)', 'O(log n)', 'O(1)'],
        correctIndex: 2,
        explanation: 'Each iteration halves the remaining search space, so at most log₂(n) iterations are needed.',
      ),
      QuizQuestion(
        question: 'When should you set `left = mid + 1` in binary search?',
        options: [
          'When target < arr[mid]',
          'When target > arr[mid]',
          'When target == arr[mid]',
          'When the array has even length',
        ],
        correctIndex: 1,
        explanation: 'If target > arr[mid], the answer must be in the right half, so we move left past mid.',
      ),
    ],

    // ── Greedy ───────────────────────────────────────────────────────────────
    'greedy': [
      QuizQuestion(
        question: 'A greedy algorithm...',
        options: [
          'Explores all possible solutions (brute force)',
          'Makes the locally optimal choice at each step',
          'Always uses dynamic programming',
          'Always finds the global optimum for every problem',
        ],
        correctIndex: 1,
        explanation: 'Greedy picks the best-looking option at each step without reconsidering past choices.',
      ),
      QuizQuestion(
        question: 'Which problem is solved optimally by a greedy algorithm?',
        options: [
          'Longest Common Subsequence',
          '0/1 Knapsack',
          'Activity Selection (maximize non-overlapping intervals)',
          'All-Pairs Shortest Path',
        ],
        correctIndex: 2,
        explanation: 'Selecting the activity that ends earliest always maximizes the number of non-overlapping activities.',
      ),
      QuizQuestion(
        question: 'When does a greedy algorithm guarantee the optimal solution?',
        options: [
          'Always',
          'When the problem has the greedy-choice property',
          'When the input is already sorted',
          'Only for inputs with ≤ 100 elements',
        ],
        correctIndex: 1,
        explanation: 'A problem must have optimal substructure and the greedy-choice property for greedy to be provably optimal.',
      ),
    ],

    // ── Dynamic Programming 1D ───────────────────────────────────────────────
    'dp-1d': [
      QuizQuestion(
        question: 'Dynamic programming is characterized by...',
        options: [
          'Using random data structures',
          'Solving overlapping subproblems by caching intermediate results',
          'Always using recursion without memoization',
          'Solving only linear-time problems',
        ],
        correctIndex: 1,
        explanation: 'DP avoids recomputing the same subproblem twice by storing (memoizing) the result.',
      ),
      QuizQuestion(
        question: 'Space complexity of the optimized Fibonacci DP solution?',
        options: ['O(n²)', 'O(n)', 'O(1)', 'O(log n)'],
        correctIndex: 2,
        explanation: 'By keeping only the last two values instead of the full array, space drops from O(n) to O(1).',
      ),
      QuizQuestion(
        question: 'Which of these is a 1D DP problem?',
        options: [
          'Matrix Chain Multiplication',
          'Edit Distance (two strings)',
          'House Robber — max sum of non-adjacent elements',
          'Grid Unique Paths (2D grid)',
        ],
        correctIndex: 2,
        explanation: 'House Robber only needs a single 1D array dp[i] = max profit up to house i.',
      ),
    ],

    // ── Dynamic Programming 2D ───────────────────────────────────────────────
    'dp-2d': [
      QuizQuestion(
        question: '2D DP typically stores state in...',
        options: [
          'A 1D array',
          'A hash map',
          'A 2D table where dp[i][j] encodes a subproblem',
          'A priority queue',
        ],
        correctIndex: 2,
        explanation: '2D DP problems involve two changing parameters (e.g., two string indices), requiring a 2D table.',
      ),
      QuizQuestion(
        question: 'Space complexity of the standard 2D DP solution for Edit Distance?',
        options: ['O(n)', 'O(n + m)', 'O(n × m)', 'O(n²)'],
        correctIndex: 2,
        explanation: 'We need dp[i][j] for every pair of prefixes (length i of s1 and length j of s2).',
      ),
      QuizQuestion(
        question: 'Which is a classic 2D DP problem?',
        options: [
          'House Robber',
          'Longest Palindromic Substring',
          'Fibonacci Sequence',
          'Jump Game I',
        ],
        correctIndex: 1,
        explanation: 'Longest Palindromic Substring uses dp[i][j] = whether s[i..j] is a palindrome, a 2D state.',
      ),
    ],

    // ── Stack ────────────────────────────────────────────────────────────────
    'stack': [
      QuizQuestion(
        question: 'A Stack follows which access principle?',
        options: ['FIFO (First In First Out)', 'LIFO (Last In First Out)', 'Random access', 'Priority-based ordering'],
        correctIndex: 1,
        explanation: 'The last element pushed is the first one popped — Last In First Out.',
      ),
      QuizQuestion(
        question: 'Which problem is classically solved using a Stack?',
        options: [
          'Level-order tree traversal (BFS)',
          'Finding the shortest path between two nodes',
          'Validating balanced parentheses',
          'Sorting an unsorted array',
        ],
        correctIndex: 2,
        explanation: 'A stack naturally matches open brackets with the most recent unmatched close bracket.',
      ),
      QuizQuestion(
        question: 'Time complexity of push and pop on a Stack?',
        options: ['O(n)', 'O(log n)', 'O(n log n)', 'O(1)'],
        correctIndex: 3,
        explanation: 'Push appends to the top and pop removes the top — both are constant-time operations.',
      ),
    ],

    // ── BFS / Tree Traversal ─────────────────────────────────────────────────
    'bfs-trees': [
      QuizQuestion(
        question: 'BFS (Breadth-First Search) internally uses which data structure?',
        options: ['Stack', 'Queue', 'Priority Queue', 'Hash Map'],
        correctIndex: 1,
        explanation: 'A queue guarantees nodes are processed in the order they were discovered (level by level).',
      ),
      QuizQuestion(
        question: 'BFS on a tree visits nodes in which order?',
        options: [
          'Pre-order (root → left → right)',
          'In-order (left → root → right)',
          'Level-order (top to bottom, left to right)',
          'Depth-first order',
        ],
        correctIndex: 2,
        explanation: 'BFS processes all nodes at depth d before any node at depth d+1 — that is level-order.',
      ),
      QuizQuestion(
        question: 'Time complexity of BFS on a graph with V vertices and E edges?',
        options: ['O(V²)', 'O(V + E)', 'O(V log V)', 'O(E log E)'],
        correctIndex: 1,
        explanation: 'BFS visits each vertex once (O(V)) and processes each edge once (O(E)), giving O(V + E).',
      ),
    ],

    // ── DFS / Backtracking ───────────────────────────────────────────────────
    'dfs-backtracking': [
      QuizQuestion(
        question: 'Backtracking is used when...',
        options: [
          'You need the shortest path between two nodes',
          'You need to explore all candidates and prune invalid ones early',
          'The input is already sorted',
          'The problem can be solved greedily',
        ],
        correctIndex: 1,
        explanation: 'Backtracking explores a candidate solution incrementally and abandons it as soon as it violates constraints.',
      ),
      QuizQuestion(
        question: 'In the N-Queens problem, backtracking...',
        options: [
          'Finds the first valid placement using BFS',
          'Places queens one row at a time and backtracks on conflict',
          'Uses DP to precompute placements',
          'Sorts positions before placing queens',
        ],
        correctIndex: 1,
        explanation: 'The algorithm tries each column in the current row, and if a conflict is detected it undoes the last placement and tries the next option.',
      ),
      QuizQuestion(
        question: 'Space complexity of DFS is...',
        options: [
          'O(1)',
          'O(h), where h is the maximum recursion depth',
          'O(n²)',
          'Always O(V + E)',
        ],
        correctIndex: 1,
        explanation: 'The call stack grows to the depth of the recursion/tree, so space is O(h).',
      ),
    ],

    // ── Union-Find ───────────────────────────────────────────────────────────
    'union-find': [
      QuizQuestion(
        question: 'Union-Find (Disjoint Set Union) is used to...',
        options: [
          'Sort elements efficiently',
          'Find shortest paths in a graph',
          'Track connected components and detect cycles',
          'Binary search in sorted arrays',
        ],
        correctIndex: 2,
        explanation: 'DSU merges sets (union) and checks connectivity (find) — perfect for detecting cycles and connected components.',
      ),
      QuizQuestion(
        question: 'With path compression and union by rank, amortized time per operation is...',
        options: ['O(n)', 'O(log n)', 'O(α(n)) — nearly O(1)', 'O(n log n)'],
        correctIndex: 2,
        explanation: 'α is the inverse Ackermann function — it grows so slowly that for any practical n it is ≤ 4.',
      ),
      QuizQuestion(
        question: "Kruskal's MST algorithm uses Union-Find to...",
        options: [
          'Sort edges by weight',
          'Detect if adding an edge creates a cycle',
          'Calculate shortest paths',
          'Find the minimum-degree vertex',
        ],
        correctIndex: 1,
        explanation: "Kruskal's adds the cheapest edge that doesn't form a cycle — Union-Find answers the cycle-detection query in near O(1).",
      ),
    ],

    // ── Linked List ──────────────────────────────────────────────────────────
    'linked-list': [
      QuizQuestion(
        question: 'Time complexity of accessing the k-th element in a singly linked list?',
        options: ['O(1)', 'O(log n)', 'O(k) — linear in k', 'O(k²)'],
        correctIndex: 2,
        explanation: 'Unlike arrays, linked lists have no random access — you must traverse node-by-node from the head.',
      ),
      QuizQuestion(
        question: 'The "fast & slow pointer" technique in linked lists is used to...',
        options: [
          'Sort the linked list',
          'Detect a cycle (Floyd\'s algorithm)',
          'Reverse the linked list',
          'Find the maximum element',
        ],
        correctIndex: 1,
        explanation: 'If the fast pointer (2×speed) meets the slow pointer, a cycle exists. If it reaches null, the list is acyclic.',
      ),
      QuizQuestion(
        question: 'Advantage of a doubly linked list over a singly linked list?',
        options: [
          'Faster search time',
          'Less memory per node',
          'Bidirectional traversal — both forward and backward',
          'O(1) random access by index',
        ],
        correctIndex: 2,
        explanation: 'Each node stores both next and prev pointers, enabling O(1) backward traversal and insertion/deletion given a pointer.',
      ),
    ],

    // ── Heap / Priority Queue ────────────────────────────────────────────────
    'heap': [
      QuizQuestion(
        question: 'A Min-Heap guarantees...',
        options: [
          'The maximum element is at the root',
          'The minimum element is at the root',
          'All levels are completely filled',
          'Elements are in sorted order',
        ],
        correctIndex: 1,
        explanation: 'In a min-heap every parent ≤ its children, so the root is always the global minimum.',
      ),
      QuizQuestion(
        question: 'Time complexity of inserting into a heap of size n?',
        options: ['O(1)', 'O(log n)', 'O(n)', 'O(n log n)'],
        correctIndex: 1,
        explanation: 'Insertion adds to the end then bubbles up — in the worst case this touches every level, giving O(log n).',
      ),
      QuizQuestion(
        question: 'Which problem pattern naturally uses a Heap?',
        options: [
          'Binary search on a sorted array',
          'Finding the K largest/smallest elements in a stream',
          'Checking balanced parentheses',
          'Counting character frequencies',
        ],
        correctIndex: 1,
        explanation: 'A min-heap of size K efficiently tracks the K largest elements seen so far with O(n log K) total cost.',
      ),
    ],

    // ── Trie (Prefix Tree) ───────────────────────────────────────────────────
    'trie': [
      QuizQuestion(
        question: 'A Trie is optimised for...',
        options: [
          'Numeric range queries',
          'Prefix-based string searching',
          'Topological sorting',
          'Finding maximum flow in a graph',
        ],
        correctIndex: 1,
        explanation: 'Each edge in a Trie represents one character, so all words sharing a prefix share the same nodes.',
      ),
      QuizQuestion(
        question: 'Time complexity of inserting a word of length L into a Trie?',
        options: ['O(1)', 'O(log n)', 'O(L)', 'O(n)'],
        correctIndex: 2,
        explanation: 'We traverse or create one node per character in the word, giving O(L).',
      ),
      QuizQuestion(
        question: 'Which application benefits most from a Trie?',
        options: [
          'Sorting integers efficiently',
          'Finding the shortest path between cities',
          'Autocomplete and spell-check',
          'Detecting cycles in a directed graph',
        ],
        correctIndex: 2,
        explanation: 'Tries let you retrieve all words sharing a given prefix in O(prefix_length + results) time — ideal for autocomplete.',
      ),
    ],
  };

  /// Returns the questions for [techniqueId], or an empty list if none.
  static List<QuizQuestion> forTechnique(String techniqueId) =>
      questions[techniqueId] ?? [];
}
