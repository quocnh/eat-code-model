#!/bin/bash
# Strip extended attributes that interfere with iOS codesigning (e.g., Google Drive metadata)
find . -type f -print0 | xargs -0 xattr -c 2>/dev/null || true
echo "✓ Extended attributes stripped from iOS directory"
