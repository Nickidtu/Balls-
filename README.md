# Balls

Dette program viser en samling bolde, der bevæger sig rundt på skærmen og følger hinanden.
Det er lavet i C og bruger grafikbiblioteket raylib.
Der er brugt structs og pointere til at gemme information om hver bold, som for eksempel position, hastighed, farve og hvilken anden bold den følger.

Programmet laver 10 bolde, som hver får en tilfældig startposition og farve.
Hver bold får også en tilfældig anden bold, som den “følger” ved hele tiden at bevæge sig lidt i dens retning.
Når en bold rammer kanten af vinduet, hopper den tilbage (bouncer) med lidt mindre fart.
Der bliver også tegnet grå streger mellem bolde, så man kan se, hvem der følger hvem.

Der er lavet en funktion UpdateBall() som opdaterer én bold ad gangen.
Her bruges pointere (->) til at ændre værdierne i boldens struct direkte.
I main-funktionen kaldes UpdateBall() for alle bolde i hver frame.



Programmet viser, hvordan man:

Bruger structs til at samle data.

Bruger pointere til at pege på andre structs.

Tegner og opdaterer grafik med raylib.
