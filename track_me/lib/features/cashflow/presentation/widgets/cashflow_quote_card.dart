import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/cashflow_quotes_data.dart';

/// Motivational Quote Card for Cash Flow screen matching Goal & Habit Tracker design.
///
/// Features signature royal purple gradient, glowing shadow, clean typography,
/// and the 3D financial illustration banner with interactive tap to randomize quote.
class CashFlowQuoteCard extends StatefulWidget {
  const CashFlowQuoteCard({super.key});

  @override
  State<CashFlowQuoteCard> createState() => _CashFlowQuoteCardState();
}

class _CashFlowQuoteCardState extends State<CashFlowQuoteCard> {
  int _quoteIndex = 0;

  @override
  void initState() {
    super.initState();
    _quoteIndex = Random().nextInt(kCashFlowQuotes.length);
  }

  void _nextQuote() {
    setState(() {
      int next;
      do {
        next = Random().nextInt(kCashFlowQuotes.length);
      } while (next == _quoteIndex && kCashFlowQuotes.length > 1);
      _quoteIndex = next;
    });
  }

  Widget _buildHighlightedQuote(String text) {
    final highlightWords = [
      'money', 'wealth', 'save', 'saving', 'savings', 'spend', 'spending',
      'budget', 'budgeting', 'goals', 'goal', 'freedom', 'interest',
      'investment', 'invest', 'investing', 'discipline', 'future', 'peace',
      'compound', 'financial', 'growth', 'flow', 'capital', 'value', 'assets',
      'plan', 'planning', 'rupee', 'rupees', 'reserve', 'reserves', 'prosperity',
      'prosperity', 'master', 'mastery', 'security', 'frugality'
    ];

    final words = text.split(' ');
    final spans = <TextSpan>[];

    for (int i = 0; i < words.length; i++) {
      final rawWord = words[i];
      final cleanWord = rawWord.replaceAll(RegExp(r'[^\w\-]'), '').toLowerCase();
      final isHighlight = highlightWords.contains(cleanWord);

      spans.add(
        TextSpan(
          text: rawWord + (i < words.length - 1 ? ' ' : ''),
          style: TextStyle(
            fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w600,
            color: isHighlight ? Colors.white : Colors.white.withOpacity(0.92),
          ),
        ),
      );
    }

    return RichText(
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 15.0,
          fontWeight: FontWeight.w600,
          height: 1.35,
          color: Colors.white,
        ),
        children: spans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuote = kCashFlowQuotes[_quoteIndex];
    final cleanAuthor = currentQuote.author
        .replaceAll('Inspired by ', '')
        .trim();

    return GestureDetector(
      onTap: _nextQuote,
      child: Container(
        height: 168,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF5F4DE1),
          gradient: const LinearGradient(
            colors: [Color(0xFF5F4DE1), Color(0xFF5143CA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5F4DE1).withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Background Hero Banner Graphic (Artwork on Right)
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/cashflow_hero_banner.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),

                  // Left Accent Vertical Line
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      color: const Color(0xFF8B6EF5),
                    ),
                  ),

                  // Left Quote Text Content (strictly left side)
                  Positioned(
                    left: 18,
                    top: 14,
                    bottom: 14,
                    right: constraints.maxWidth * 0.44,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '“',
                              style: TextStyle(
                                fontSize: 32,
                                height: 0.85,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFC4B5FD),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _buildHighlightedQuote(
                                currentQuote.quote,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Text(
                            '– $cleanAuthor',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFC4B5FD),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
