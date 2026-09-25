import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;

class ChessBoardWidget extends StatelessWidget {
  final chess_lib.Chess game;
  final String? selectedSquare; // e.g. 'e4'
  final List<String> validMoves; // e.g. ['e5', 'e6']
  final Map<String, String>? lastMove; // {'from': 'e2', 'to': 'e4'}
  final bool isFlipped; // true if Black perspective
  final ValueChanged<String> onSquareTap;

  const ChessBoardWidget({
    super.key,
    required this.game,
    required this.selectedSquare,
    required this.validMoves,
    required this.lastMove,
    required this.isFlipped,
    required this.onSquareTap,
  });

  /// Map piece to unicode representation
  static String _getPieceSymbol(chess_lib.Piece? piece) {
    if (piece == null) return '';
    final isWhite = piece.color == chess_lib.Color.WHITE;
    switch (piece.type) {
      case chess_lib.PieceType.PAWN:
        return isWhite ? '♙' : '♟';
      case chess_lib.PieceType.KNIGHT:
        return isWhite ? '♘' : '♞';
      case chess_lib.PieceType.BISHOP:
        return isWhite ? '♗' : '♝';
      case chess_lib.PieceType.ROOK:
        return isWhite ? '♖' : '♜';
      case chess_lib.PieceType.QUEEN:
        return isWhite ? '♕' : '♛';
      case chess_lib.PieceType.KING:
        return isWhite ? '♔' : '♚';
      default:
        return '';
    }
  }

  /// Finds king square if in check
  String? _getCheckedKingSquare() {
    if (!game.in_check) return null;
    final kingColor = game.turn;
    final files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];

    for (int rank = 1; rank <= 8; rank++) {
      for (final file in files) {
        final squareId = '$file$rank';
        final p = game.get(squareId);
        if (p != null && p.type == chess_lib.PieceType.KING && p.color == kingColor) {
          return squareId;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final checkedKing = _getCheckedKingSquare();

    final lightSquareColor = const Color(0xFFF0D9B5);
    final darkSquareColor = const Color(0xFFB58863);
    final selectedColor = const Color(0xFFBAC64B);
    final lastMoveColor = const Color(0x80CDD26A);
    final checkColor = const Color(0xFFE63946);

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: List.generate(8, (rankIndex) {
            final actualRank = isFlipped ? rankIndex + 1 : 8 - rankIndex;

            return Expanded(
              child: Row(
                children: List.generate(8, (fileIndex) {
                  final actualFileIndex = isFlipped ? 7 - fileIndex : fileIndex;
                  final fileChar = String.fromCharCode('a'.codeUnitAt(0) + actualFileIndex);
                  final squareId = '$fileChar$actualRank';

                  final isLight = (actualRank + actualFileIndex) % 2 != 0;
                  final piece = game.get(squareId);
                  final isSelected = selectedSquare == squareId;
                  final isValidDestination = validMoves.contains(squareId);
                  final isLastMove = lastMove != null &&
                      (lastMove!['from'] == squareId || lastMove!['to'] == squareId);
                  final isKingInCheck = checkedKing == squareId;

                  Color squareColor = isLight ? lightSquareColor : darkSquareColor;
                  if (isSelected) {
                    squareColor = selectedColor;
                  } else if (isLastMove) {
                    squareColor = Color.alphaBlend(lastMoveColor, squareColor);
                  }

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onSquareTap(squareId),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: isKingInCheck ? checkColor : squareColor,
                            ),
                            child: Center(
                              child: Text(
                                _getPieceSymbol(piece),
                                style: TextStyle(
                                  fontSize: 34,
                                  height: 1.0,
                                  color: piece?.color == chess_lib.Color.WHITE
                                      ? Colors.white
                                      : const Color(0xFF1E1E1E),
                                  shadows: [
                                    Shadow(
                                      color: piece?.color == chess_lib.Color.WHITE
                                          ? Colors.black54
                                          : Colors.white24,
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Coordinate labels
                          if (fileIndex == 0)
                            Positioned(
                              top: 2,
                              left: 3,
                              child: Text(
                                '$actualRank',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isLight ? darkSquareColor : lightSquareColor,
                                ),
                              ),
                            ),
                          if (rankIndex == 7)
                            Positioned(
                              bottom: 2,
                              right: 3,
                              child: Text(
                                fileChar,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isLight ? darkSquareColor : lightSquareColor,
                                ),
                              ),
                            ),
                          // Legal move destination dot indicator
                          if (isValidDestination)
                            Center(
                              child: Container(
                                width: piece != null ? 36 : 14,
                                height: piece != null ? 36 : 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: piece != null
                                      ? colors.error.withValues(alpha: 0.4)
                                      : Colors.black.withValues(alpha: 0.25),
                                  border: piece != null
                                      ? Border.all(color: colors.error, width: 2.5)
                                      : null,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }
}
