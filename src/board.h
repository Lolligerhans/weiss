// board.h

#pragma once

#include "types.h"


uint8_t SqDistance[64][64];


const int NonPawn[PIECE_NB];
const int PiecePawn[PIECE_NB];
const int PhaseValue[PIECE_NB];


void ParseFen(const char *fen, Position *pos);
#ifndef NDEBUG
void PrintBoard(const Position *pos);
bool CheckBoard(const Position *pos);
#endif
#ifdef DEV
void PrintBoard(const Position *pos);
void MirrorBoard(Position *pos);
#endif

// Mirrors a square horizontally
INLINE int MirrorSquare(const int sq) {
    return sq ^ 56;
}

// Returns distance between sq1 and sq2
INLINE int Distance(const int sq1, const int sq2) {
    return SqDistance[sq1][sq2];
}

INLINE int RelativeRank(const int side, const int rank) {
    return side == WHITE ? rank : RANK_8 - rank;
}