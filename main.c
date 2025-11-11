#include "raylib.h"  // <- Ændret til lowercase
#include <stddef.h>  // <- TILFØJET for NULL definition
#include <math.h>    // <- TILFØJET for sqrtf

// *** STRUCT DEFINITION *** - Definerer en Ball datatype
typedef struct Ball {
    float posx;       // STRUCT MEMBER: x-position
    float posy;       // STRUCT MEMBER: y-position
    float velx;       // STRUCT MEMBER: x-hastighed
    float vely;       // STRUCT MEMBER: y-hastighed
    float radius;     // STRUCT MEMBER: kuglens radius
    Color color;      // STRUCT MEMBER: raylib farve (r,g,b,a)
    struct Ball *follows; // *** POINTER MEMBER *** - pointer til en anden Ball struct
} Ball;

#define NUM_BALLS 10
#define SCREEN_WIDTH 800
#define SCREEN_HEIGHT 600
#define MAX_SPEED 3.0f

// *** STRUCT ARRAY *** - Array af Ball structs
Ball balls[NUM_BALLS];

void InitializeBalls() {
    for (int i = 0; i < NUM_BALLS; i++) {
        // *** STRUCT DOT NOTATION *** - Tilgår struct medlemmer direkte (med bedre ranges)
        balls[i].posx = GetRandomValue(100, SCREEN_WIDTH - 100);   // STRUCT.MEMBER (ikke for tæt på kanten)
        balls[i].posy = GetRandomValue(100, SCREEN_HEIGHT - 100);  // STRUCT.MEMBER
        balls[i].velx = GetRandomValue(-2, 2);                     // STRUCT.MEMBER (lavere starthastighed)
        balls[i].vely = GetRandomValue(-2, 2);                     // STRUCT.MEMBER
        balls[i].radius = GetRandomValue(15, 25);                  // STRUCT.MEMBER (mindre variation)
        
        // *** STRUCT INITIALIZATION *** - Opretter Color struct inline
        balls[i].color = (Color){ GetRandomValue(100, 255), GetRandomValue(100, 255), GetRandomValue(100, 255), 255 };

        // vælg en tilfældig bold at følge (ikke sig selv)
        int followIndex;
        do {
            followIndex = GetRandomValue(0, NUM_BALLS - 1);
        } while (followIndex == i);

        // *** POINTER ASSIGNMENT *** - Sætter pointer til at pege på anden struct
        balls[i].follows = &balls[followIndex];  // & = ADDRESS-OF OPERATOR (får pointer til balls[followIndex])
    }
}

// *** FUNCTION PARAMETER POINTER *** - Modtager pointer til Ball struct
void UpdateBall(Ball *b) {  // b er en POINTER til en Ball struct
    
    // *** FØLGE-LOGIK MED BEDRE KONTROL ***
    if (b->follows != NULL) {  // *** POINTER NULL CHECK *** - Checker om pointer er gyldig
        // *** CHAINED POINTER ACCESS *** - Følger pointer til anden struct og tilgår dens medlemmer
        float dx = b->follows->posx - b->posx;  // POINTER->POINTER->MEMBER minus POINTER->MEMBER
        float dy = b->follows->posy - b->posy;  // POINTER->POINTER->MEMBER minus POINTER->MEMBER
        
        float distance = sqrtf(dx * dx + dy * dy);
        
        // Kun påvirk hvis der er afstand (undgå division med nul)
        if (distance > 0) {
            // Normaliser retning og anvend mindre kraft
            dx /= distance;
            dy /= distance;
            b->velx += dx * 0.005f; // *** POINTER->MEMBER *** (meget mindre påvirkning)
            b->vely += dy * 0.005f; // *** POINTER->MEMBER ***
        }
    }
    
    // *** HASTIGHEDSBEGRÆNSNING *** - Forhindrer ukontrolleret acceleration
    float speed = sqrtf(b->velx * b->velx + b->vely * b->vely);
    if (speed > MAX_SPEED) {
        b->velx = (b->velx / speed) * MAX_SPEED; // *** POINTER->MEMBER ***
        b->vely = (b->vely / speed) * MAX_SPEED; // *** POINTER->MEMBER ***
    }

    // *** POINTER ARROW NOTATION *** - Tilgår struct medlemmer gennem pointer
    b->posx += b->velx;  // POINTER->MEMBER (samme som (*b).posx)
    b->posy += b->vely;  // POINTER->MEMBER (samme som (*b).posy)

    // *** BOUNDARY CHECKING *** - Hold bolde inden for skærmen
    if (b->posx - b->radius <= 0 || b->posx + b->radius >= SCREEN_WIDTH) {
        b->velx = -b->velx * 0.8f;  // Bounce med energitab
        b->posx = fmaxf(b->radius, fminf(SCREEN_WIDTH - b->radius, b->posx));
    }
    if (b->posy - b->radius <= 0 || b->posy + b->radius >= SCREEN_HEIGHT) {
        b->vely = -b->vely * 0.8f;  // Bounce med energitab
        b->posy = fmaxf(b->radius, fminf(SCREEN_HEIGHT - b->radius, b->posy));
    }
}

int main(void) {
    InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Balls Simulation - Improved");
    SetTargetFPS(60);
    
    InitializeBalls();

    while (!WindowShouldClose()) {
        // Update alle bolde
        for (int i = 0; i < NUM_BALLS; i++) {
            // *** FUNCTION CALL MED POINTER *** - Sender adresse på struct til funktion
            UpdateBall(&balls[i]);  // & = ADDRESS-OF OPERATOR (laver pointer til balls[i])
        }

        // Draw
        BeginDrawing();
        ClearBackground(BLACK);
        
        for (int i = 0; i < NUM_BALLS; i++) {
            // *** STRUCT DOT NOTATION *** - Tilgår struct medlemmer direkte (ikke pointer)
            DrawCircle((int)balls[i].posx, (int)balls[i].posy, balls[i].radius, balls[i].color);
            
            // *** TEGN FORBINDELSESLINJE *** - Viser hvilket bold følger hvilket
            if (balls[i].follows != NULL) {
                DrawLine((int)balls[i].posx, (int)balls[i].posy, 
                        (int)balls[i].follows->posx, (int)balls[i].follows->posy, 
                        GRAY);
            }
        }
        
        DrawText("Balls following each other (with boundaries)", 10, 10, 20, WHITE);
        DrawText("Gray lines show following relationships", 10, 35, 16, LIGHTGRAY);
        EndDrawing();
    }
    
    CloseWindow();
    return 0;
}
