// simple blackjack prototype.
//
// I'm porting this to boot sector assembly, so
// that's why its coded a little strangely.
//
// gcc blackjack.c -Wall -o blackjack; ./blackjack

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define HAND_SIZE 6
#define DECK_SIZE 52


u_int8_t deck[DECK_SIZE];
//   spades   = deck[0:12]
//   clubs    = deck[13:25]
//   diamonds = deck[26:38]
//   hearts   = deck[39:51]
//
// convert val to suit/face:  (suit, face) := ((deck[i] / 13), (deck[i] % 13))
//
//  J,Q,K = 10; 
//  A = (hand >= 11) ? 1 : 11  - check on this?

u_int8_t playerHand[HAND_SIZE];
u_int8_t dealerHand[HAND_SIZE];

u_int8_t isPlaying = 1;
u_int8_t gameRound = 0;
u_int8_t choice = 0;
u_int8_t wins = 0;

int main(void) {
    srand(time(NULL));

    // place bet?

    // shuffle deck in place - https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle
    
    // deal one card to player
    // deal one card to dealer (hide)
    // deal one card to player
    // deal one card to dealer (show)

    while (isPlaying) {

        // while player < 21; hit, stand, or quit ?
        // check bust

        // dealer flip hidden
        // while dealer < 17; dealer hits  (soft 17)
        // check bust
        
        // check win/loss

        gameRound++;
    }

    return 0;
}


