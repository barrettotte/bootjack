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

// empty input buffer
void clearInputBuffer() {
    char c;
    do {
        c = getchar();
    } while (c != '\n' && c != EOF);
}

// print card using deck index
void printCard(uint8_t card) {
    uint8_t suit = card / 13;
    uint8_t face = card % 13;

    switch(face) {
        case 0:   printf("Ace");           break;
        case 10:  printf("Jack");          break;
        case 11:  printf("Queen");         break;
        case 12:  printf("King");          break;
        default:  printf("%d", face + 1);  break;
    }
    printf(" of ");
    switch(suit) {
        case SUIT_CLUBS:     printf("Clubs");     break;
        case SUIT_DIAMONDS:  printf("Diamonds");  break;
        case SUIT_HEARTS:    printf("Hearts");    break;
        case SUIT_SPADES:    printf("Spades");    break;
    }
    printf("\n");
}

// print each card in hand
void printHand(uint8_t* hand, uint8_t dealt, uint8_t isPlayer, uint8_t score) {
    printf("%s: %d\n", (isPlayer) ? "player" : "dealer", score);
    for (uint8_t i = 0; i < dealt; i++) {
        printf("  - ");
        printCard(hand[i]);
    }
}

// get score of target hand
uint8_t evalHand(uint8_t* hand, uint8_t dealt) {
    uint8_t score = 0;

    for (uint8_t i = 0; i < dealt; i++) {
        uint8_t face = hand[i] % 13;

        if (face == 0) {
            score += (score < 11) ? 11 : 1;  // ace
        } else if (face >= 10) {
            score += 10;  // jack, queen, king
        } else {
            score += (face + 1);
        }
    }
    return score;
}

int main(void) {
    srand(time(NULL));

    uint8_t deck[DECK_SIZE];
    uint8_t deckIdx = 0;

    uint8_t playerHand[HAND_SIZE];
    uint8_t playerIdx = 0;
    uint8_t playerScore = 0;

    uint8_t dealerHand[HAND_SIZE];
    uint8_t dealerIdx = 0;
    uint8_t dealerScore = 0;

    uint8_t choice = 0;
    // uint8_t wins = 0;
    // uint8_t losses = 0;

    for (uint8_t i = 0; i < DECK_SIZE; i++) {
        deck[i] = i;
    }

    while (1) {
        for (uint8_t i = 0; i < HAND_SIZE; i++) {
            playerHand[i] = 0;
            dealerHand[i] = 0;
        }
        shuffle(deck);
        choice = 0;
        playerIdx = 0;
        dealerIdx = 0;
        deckIdx = 0;
        playerScore = 0;
        dealerScore = 0;

        // deal initial hand
        for (uint8_t i = 0; i < 2; i++) {
            playerHand[playerIdx++] = deck[deckIdx++];
            dealerHand[dealerIdx++] = deck[deckIdx++];
        }

        while (1) {

            dealerScore = evalHand(dealerHand, dealerIdx);
            if (dealerIdx == 2) {
                printf("dealer: ??\n  - ");
                printCard(dealerHand[0]);
                printf("  - ?? of ????\n");
            } else {
                printHand(dealerHand, dealerIdx, 0, dealerScore);
            }

            playerScore = evalHand(playerHand, playerIdx);
            printHand(playerHand, playerIdx, 1, playerScore);

            while (playerScore < 21) {
                printf("\n(H)it, (S)tand, or (Q)uit ? ");
                scanf(" %c", &choice);

                if (choice == 'H' || choice == 'h') {
                    printf("Hit\n");
                    printHand(playerHand, playerIdx, 1, playerScore);
                    playerHand[playerIdx++] = deck[deckIdx++];
                    playerScore = evalHand(playerHand, playerIdx);
                } else if (choice == 'S' || choice == 's') {
                    printf("Stand\n");
                    printHand(playerHand, playerIdx, 1, playerScore);
                    break;
                } else if (choice == 'Q' || choice == 'q') {
                    printf("Quit\n");
                    return 0;
                } else {
                    printf("invalid input.\n");
                }
            }

            if (playerScore > 21) {
                // TODO: player bust
                printf("player bust\n");
            }

            // while (dealer < 17) ; soft 17
            //   hit

            // check scores

            // eval game state

            break;  // TODO:
        }
        printf("game over...\n");

        // play again?
        while (1) {
            printf("play again? (Y)es or (N)o ? ");
            scanf(" %c", &choice);

            if (choice == 'y' || choice == 'Y') {
                clearInputBuffer();
                choice = 0;
                break;
            } else if (choice == 'n' || choice == 'N') {
                return 0;
            } else {
                printf("invalid input.\n");
            }
        }
    }
    return 0;
}
