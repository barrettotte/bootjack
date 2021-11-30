// simple blackjack prototype.
//
// I'm porting this to boot sector assembly, so
// that's why its coded a little strangely.
//
// gcc blackjack.c -Wall -o blackjack; ./blackjack

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>

#define HAND_SIZE 6
#define DECK_SIZE 52

#define SUIT_CLUBS    0
#define SUIT_DIAMONDS 1
#define SUIT_HEARTS   2
#define SUIT_SPADES   3

// shuffle deck using Fisher-Yates
void shuffle(uint8_t* deck) {
    uint8_t i, j, tmp;

    for (i = DECK_SIZE - 1; i > 0; i--) {
        j = rand() % (i + 1);
        tmp = deck[j];
        deck[j] = deck[i];
        deck[i] = tmp;
    }
}

// print card using deck index
void printCard(uint8_t card) {
    uint8_t suit = card / 13;
    uint8_t face = card % 13;

    switch(face) {
        case 0:
            printf("Ace");
            break;
        case 10:
            printf("Jack");
            break;
        case 11:
            printf("Queen");
            break;
        case 12:
            printf("King");
            break;
        default:
            printf("%d", face + 1);
            break;
    }
    printf(" of ");
    switch(suit) {
        case SUIT_CLUBS:
            printf("Clubs");
            break;
        case SUIT_DIAMONDS:  
            printf("Diamonds");
            break;
        case SUIT_HEARTS:
            printf("Hearts");
            break;
        case SUIT_SPADES:
            printf("Spades");
            break;
    }
    printf("\n");
}

int main(void) {
    srand(time(NULL));

    uint8_t deck[DECK_SIZE];
    //   spades   = deck[0:12]
    //   clubs    = deck[13:25]
    //   diamonds = deck[26:38]
    //   hearts   = deck[39:51]
    //
    //  A = (hand >= 11) ? 1 : 11  - check on this?

    uint8_t playerHand[HAND_SIZE];
    uint8_t dealerHand[HAND_SIZE];

    uint8_t playing = 1;
    uint8_t matchActive = 1;
    uint8_t choice = 0;

    uint8_t deckIdx = 0;
    uint8_t playerIdx = 0;
    uint8_t dealerIdx = 0;

    uint8_t wins = 0;
    uint8_t losses = 0;

    // init deck and hands
    for (uint8_t i = 0; i < DECK_SIZE; i++) {
        deck[i] = i;
    }

    while (playing) {
        
        // init
        for (uint8_t i = 0; i < HAND_SIZE; i++) {
            playerHand[i] = 0;
            dealerHand[i] = 0;
        }
        shuffle(deck);

        // deal initial hand
        for (uint8_t i = 0; i < 2; i++) {
            playerHand[playerIdx++] = deck[deckIdx++];
            dealerHand[dealerIdx++] = deck[deckIdx++];

            printf("player: ");
            printCard(playerHand[playerIdx-1]);
            printf("dealer: ");
            printCard(dealerHand[dealerIdx-1]);
        }

        while (matchActive) {
            // check if blackjack occurred immediately (Ace + 10)

            // get player option - hit,stand,quit

            // print player hand

            // check win or bust

            // if (!stand)
            //   show dealer card
            //   while (dealer < 17) ; soft 17
            //     hit
            //     print card

            // check scores
            // eval game state

            break;  // TODO:
        }

        // play again?

        break; // TODO: remove
    }

    return 0;
}


