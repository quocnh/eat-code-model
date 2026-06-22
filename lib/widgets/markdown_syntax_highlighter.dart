import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:google_fonts/google_fonts.dart';

class SyntaxHighlightMarkdownBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element.tag == 'code' && element.attributes['class'] != null) {
      final language = element.attributes['class']!.replaceAll('language-', '');
      
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (language.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Text(
                  language,
                  style: GoogleFonts.firaCode(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 300, // Minimum width to ensure proper display
                ),
                child: IntrinsicWidth(
                  child: HighlightView(
                    // Add two spaces of padding to preserve indentation
                    '  ${element.textContent}',
                    language: language,
                    theme: githubTheme,
                    padding: const EdgeInsets.all(16),
                    textStyle: GoogleFonts.firaCode(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return null;
  }
}

// Custom text styles for markdown elements
class MarkdownStyles {
  static MarkdownStyleSheet getStyleSheet(BuildContext context) {
    return MarkdownStyleSheet(
      p: const TextStyle(
        fontSize: 16,
        height: 1.5,
      ),
      h1: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        height: 1.5,
      ),
      h2: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        height: 1.5,
      ),
      h3: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        height: 1.5,
      ),
      strong: const TextStyle(fontWeight: FontWeight.bold),
      em: const TextStyle(fontStyle: FontStyle.italic),
      listBullet: const TextStyle(fontSize: 16),
      code: GoogleFonts.firaCode(
        backgroundColor: Colors.grey[200],
        fontSize: 14,
        height: 1.5,
      ),
      codeblockPadding: const EdgeInsets.all(8),
      codeblockDecoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      blockquote: TextStyle(
        color: Colors.grey[700],
        fontStyle: FontStyle.italic,
        fontSize: 16,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Colors.grey[300]!,
            width: 4,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.only(left: 16),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
    );
  }
}