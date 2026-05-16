#set page(paper: "a4", margin: 2.5cm)
#set text(font: "New Computer Modern", size: 11pt, lang: "pl")
#set par(justify: true, leading: 0.65em)
#set heading(numbering: "1.")

#align(center)[
  #text(size: 17pt, weight: "bold")[Sprawozdanie z Zadania: Systemy Rekomendacyjne] \
  #v(0.3cm)
  #text(size: 12pt)[PDB26 - Introduction to Recommender Systems] \
  #text(size: 11pt)[Analiza algorytmu kNN oraz "Najwyżej oceniane" na zbiorze MovieLens 100k] \
  #v(0.5cm)
  #text(size: 12pt)[*Autor:* Juliusz Radziszewski (s193504)] \
  #v(0.2cm)
  #text(size: 12pt)[16.05.2026]
  #v(1cm)
]

= Wprowadzenie i środowisko badawcze
Celem niniejszego sprawozdania jest analiza, strojenie hiperparametrów i porównanie dwóch algorytmów rekomendacyjnych. Pierwszym z nich jest algorytm k-Najbliższych Sąsiadów (kNN), a drugim autorski algorytm bazowy "Najwyżej oceniane" (Top Rated).

== Zbiór danych (MovieLens 100k)
Do badań wykorzystano popularny, historyczny zbiór danych `ml-100k` udostępniony przez organizację GroupLens. Zbiór ten zawiera dokładnie 100 000 ocen (w skali od 1 do 5) wystawionych przez 943 użytkowników dla 1682 filmów. Każdy użytkownik w zbiorze ocenił co najmniej 20 filmów. Ze względu na swoją charakterystykę, macierz ocen jest w dużej mierze rzadka (sparse matrix), co stanowi typowe wyzwanie dla systemów Collaborative Filtering.

== Metryki ewaluacyjne: MAE vs RMSE
Jakość algorytmów oceniano na podstawie dwóch najpopularniejszych metryk:
- *MAE (Mean Absolute Error)* - średni błąd bezwzględny. Oblicza uśrednioną różnicę między przewidywaną a rzeczywistą oceną. Jest intuicyjna w interpretacji (wynik MAE = 0.8 oznacza, że system myli się średnio o 0.8 gwiazdki).
- *RMSE (Root Mean Squared Error)* - pierwiastek błędu średniokwadratowego. Różnica polega na tym, że przed uśrednieniem błędy są podnoszone do kwadratu. Sprawia to, że RMSE *znacznie silniej karze duże pomyłki*. W systemach rekomendacyjnych jest to kluczowe – polecenie użytkownikowi filmu, którego bardzo nie lubi (duża różnica ocen), jest uznawane za gorsze niż delikatne pomyłki na kilku filmach letnich.

= Strojenie hiperparametrów algorytmu kNN
W celu znalezienia optymalnej konfiguracji dla algorytmu `KNNBasic`, wykorzystano metodę przeszukiwania siatki (Grid Search). Przebadano następujące przestrzenie hiperparametrów:
- Liczba sąsiadów (*k*): 6 wariantów (10, 20, 30, 40, 50, 60)
- Miara podobieństwa: 3 warianty (`msd`, `cosine`, `pearson`)
- Podejście: 2 warianty (`user_based` oraz `item_based`).

*Złożoność obliczeniowa poszukiwań:* \
Powyższa przestrzeń poszukiwań dała łącznie 36 unikalnych kombinacji parametrów ($6 times 3 times 2 = 36$). Aby zapewnić maksymalną rzetelność wyników i zminimalizować wpływ losowego podziału danych, zastosowano *3-krotną walidację krzyżową (3-fold Cross-Validation)*. Oznacza to, że dla każdej z 36 kombinacji, zbiór danych był dzielony na 3 równe części, a model był trenowany i ewaluowany trzykrotnie. W efekcie, środowisko testowe musiało zbudować potężne macierze podobieństwa i przetrenować modele predykcyjne aż *108 razy*. 

Na Rysunku 1 zobrazowano, jak zmieniał się błąd RMSE w zależności od liczby sąsiadów dla wszystkich przebadanych miar i podejść. Widać wyraźnie, że najsłabiej radzi sobie korelacja Pearsona, podczas gdy miara MSD osiąga najniższe wartości błędów.

#figure(
  image("wykres_strojenie_k.png", width: 95%),
  caption: [Zależność błędu RMSE od parametru $k$ (liczby sąsiadów) uwzględniająca różne miary podobieństwa oraz podejścia user/item-based.]
)

W tabeli 1 przedstawiono pięć najlepszych wyników procesu optymalizacji uśrednionych z walidacji krzyżowej.

#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    align: (center, center, center, center, center),
    stroke: 0.5pt,
    fill: (_, row) => if row == 0 { luma(230) } else { none },
    [*Miejsce*], [*Liczba sąsiadów (k)*], [*Miara podobieństwa*], [*Podejście*], [*Średnie RMSE*],
    [1], [30], [msd], [User-based], [0.9862],
    [2], [40], [msd], [Item-based], [0.9863],
    [3], [20], [msd], [User-based], [0.9864],
    [4], [50], [msd], [Item-based], [0.9873],
    [5], [40], [msd], [User-based], [0.9875],
  ),
  caption: [Top 5 konfiguracji algorytmu kNN wyłonionych przez walidację krzyżową (Grid Search).]
)

*Decyzja:* Do ostatecznego testu wybrano algorytm kNN z liczbą sąsiadów *k=30*, miarą podobieństwa *msd* oparty na podobieństwie użytkowników (*user-based*).

= Implementacja algorytmu "Najwyżej oceniane"
Autorski algorytm wyznacza średnią ze wszystkich ocen dla każdego elementu w zbiorze treningowym. Podczas predykcji, model zachowuje się pasywnie, zwracając zapamiętaną średnią dla danego filmu bez jakiejkolwiek personalizacji. W przypadku pojawienia się w zbiorze testowym filmu nieznanego (problem *cold start*), algorytm zwraca asekuracyjnie globalną średnią wszystkich ocen ze zbioru treningowego.

= Porównanie wyników i Wnioski
Ostateczny test przeprowadzono po uprzednim podziale danych na zbiór treningowy (75%) oraz testowy (25%). Zestawienie końcowych wyników dla obu algorytmów – na danych znanych (trening) i nieznanych (test) – zaprezentowano w Tabeli 2 oraz na Rysunku 2.

#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    align: (left, center, center, center, center),
    stroke: 0.5pt,
    fill: (_, row) => if row == 0 { luma(230) } else { none },
    [*Algorytm*], [*RMSE (Trening)*], [*MAE (Trening)*], [*RMSE (Test)*], [*MAE (Test)*],
    [Zoptymalizowany kNN], [0.7247], [0.5605], [0.9833], [0.7755],
    [Autorski Top Rated], [0.9961], [0.7958], [1.0285], [0.8195],
  ),
  caption: [Zestawienie błędów RMSE i MAE dla badanych algorytmów na zbiorach treningowym i testowym.]
)

#figure(
  image("wykres_porownanie.png", width: 75%),
  caption: [Wizualizacja końcowych wartości błędu RMSE i MAE dla badanych algorytmów wyłącznie na nowym, testowym zbiorze danych.]
)

*Analiza i Wnioski:*
1. *Przewaga Collaborative Filtering:* Algorytm kNN z wynikiem RMSE 0.9833 ewidentnie pokonuje algorytm bazowy (RMSE 1.0285). Różnica ta w dziedzinie systemów rekomendacyjnych jest statystycznie bardzo istotna i świadczy o udanym odnalezieniu ukrytych preferencji. Klasyczne podejście oparte na podobieństwie użytkowników (User-based) wygrało w ostatecznym rozrachunku z podejściem opartym na elementach.
2. *Rola kary za duże błędy:* Widać wyraźnie, że metryka RMSE zawsze przyjmuje wartości wyższe niż MAE dla obu modeli (np. kNN osiąga MAE na poziomie 0.7755 przy RMSE 0.9833). Wynika to z faktu matematycznego karania za duże pomyłki.
3. *Stabilność kNN vs Overfitting:* Analizując Tabelę 2, błąd kNN na zbiorze treningowym wynosił 0.7247 (RMSE). Gorszy wynik na zbiorze testowym (0.9833) wskazuje na wyraźną obecność przeuczenia modelu do danych znanych, co jest typowym zjawiskiem w podejściu *memory-based*. Z kolei algorytm "Najwyżej Oceniane" zachowuje się bliźniaczo na obu zbiorach (RMSE ok. 1.00), ponieważ jako model statystyczny nie uczy się żadnych skomplikowanych wzorców, nie ryzykując tym samym zjawiska *overfittingu*.
4. *Złożoność pamięciowa a środowisko produkcyjne:* Warto zauważyć istotny inżynieryjny aspekt wyboru między podejściem *user-based* a *item-based*. Zbiór `ml-100k` posiada 943 użytkowników i 1682 filmy. Oznacza to, że macierz podobieństwa dla wygranego podejścia *user-based* ma rozmiar zaledwie $943 times 943$, podczas gdy dla konkurencyjnego *item-based* wynosiłaby $1682 times 1682$. Oznacza to, że zwycięski model okazał się nie tylko najdokładniejszy, ale również znacznie "lżejszy" i wymagałby mniej zasobów pamięci operacyjnej (RAM) na serwerach w ewentualnym środowisku produkcyjnym.