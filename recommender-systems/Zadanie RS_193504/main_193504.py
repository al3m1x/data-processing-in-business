import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from surprise import Dataset
from surprise import KNNBasic
from surprise import accuracy
from surprise import AlgoBase
from surprise.model_selection import GridSearchCV
from surprise.model_selection import train_test_split

# 1. INICJALIZACJA DANYCH
print("1. Pobieranie zbioru MovieLens 100k")
data = Dataset.load_builtin('ml-100k')

# 2. HIPERPARAMETRY DLA KNN
print("\n2. Start Grid Search dla algorytmu kNN")
param_grid = {
    'k': [10, 20, 30, 40, 50, 60],
    'sim_options': {
        'name': ['msd', 'cosine', 'pearson'],
        'user_based': [True, False] # True - podobieństwo użytkowników i False - podobieństwo elementów
    }
}

# Szukamy pod kątem optymalizacji RMSE i MAE, 3-krotna walidacja krzyżowa (cv=3)
gs = GridSearchCV(KNNBasic, param_grid, measures=['rmse', 'mae'], cv=3, n_jobs=-1)
gs.fit(data)

# Pobranie wyników do wykresów
cv_results = pd.DataFrame(gs.cv_results)
print("\nFragment tabeli z wynikami GridSearch:")
# Print wyników
print(cv_results[['param_k', 'param_sim_options', 'mean_test_rmse', 'mean_test_mae']].sort_values(by='mean_test_rmse').head(5))

best_k = gs.best_params['rmse']['k']
best_sim_options = gs.best_params['rmse']['sim_options']

print(f"\nNajlepsze RMSE: {gs.best_score['rmse']:.4f}")
print(f"Optymalne hiperparametry - k={best_k}, miara podobieństwa: {best_sim_options['name']}, user_based: {best_sim_options['user_based']}")


# 3. WŁASNY ALGORYTM NAJWYŻEJ OCENIANE
class TopRatedAlgo(AlgoBase):
    def __init__(self):
        AlgoBase.__init__(self)

    def fit(self, trainset):
        # Obowiązkowe wywołanie metody fit z klasy bazowej
        AlgoBase.fit(self, trainset)
        
        # Obliczenie średniej oceny dla każdego filmu (item)
        self.item_means = {}
        for i, ratings in self.trainset.ir.items():
            # ratings to lista krotek (id usera, ocena)
            self.item_means[i] = np.mean([r for (_, r) in ratings])
            
        # Obliczenie średniej globalnej w razie wystąpienia nieznanego filmu w zbiorze testowym
        self.global_mean = self.trainset.global_mean
        return self

    def estimate(self, u, i):
        # Metoda estimate musi przyjmować u (user) i i (item)
        if self.trainset.knows_item(i):
            return self.item_means[i]
        else:
            return self.global_mean


# 4. PORÓWNANIE ALGORYTMÓW (TRAIN vs TEST)
print("\n3. Porównanie ostatecznych wyników na zbiorze treningowym i testowym")
# Dzielimy zbiór danych: 75% na trening, 25% na test
trainset, testset = train_test_split(data, test_size=0.25, random_state=42)

# Konfiguracja optymalnego KNN
knn_optimal = KNNBasic(k=best_k, sim_options=best_sim_options, verbose=False)
knn_optimal.fit(trainset)

# Konfiguracja najwyżej oceniane
top_rated = TopRatedAlgo()
top_rated.fit(trainset)

# Funkcja pomocnicza do generowania predykcji
def evaluate_algo(algo, algo_name):
    # Predykcje dla zbioru treningowego
    trainset_build = trainset.build_testset()
    predictions_train = algo.test(trainset_build)
    
    # Predykcje dla zbioru testowego
    predictions_test = algo.test(testset)
    
    print(f"\n--- Algorytm: {algo_name} ---")
    print("Zbiór treningowy:")
    rmse_train = accuracy.rmse(predictions_train, verbose=False)
    mae_train = accuracy.mae(predictions_train, verbose=False)
    print(f"RMSE: {rmse_train:.4f} | MAE: {mae_train:.4f}")
    
    print("Zbiór testowy")
    rmse_test = accuracy.rmse(predictions_test, verbose=False)
    mae_test = accuracy.mae(predictions_test, verbose=False)
    print(f"RMSE: {rmse_test:.4f} | MAE: {mae_test:.4f}")

evaluate_algo(knn_optimal, "Zoptymalizowany kNN")
evaluate_algo(top_rated, "Własny Top Rated")

# 5. GENEROWANIE WYKRESÓW DO SPRAWOZDANIA
print("\n4. Generowanie wykresów i zapis do plików png")

# Wykres 1: Wpływ parametru K na RMSE (dla wszystkich miar)
results_df = pd.DataFrame(gs.cv_results)

plt.figure(figsize=(12, 7))

metrics = ['msd', 'cosine', 'pearson']
colors = {'msd': '#1f77b4', 'cosine': '#2ca02c', 'pearson': '#d62728'} # Niebieski, zielony, czerwony
markers = {True: 'o', False: 's'} # Kółko dla user-based, kwadrat dla item-based
labels_dict = {True: 'User-based', False: 'Item-based'}

# Pętla generująca linie dla każdej kombinacji
for metric in metrics:
    df_metric = results_df[results_df['param_sim_options'].apply(lambda x: x['name'] == metric)]
    for is_user_based in [True, False]:
        df_final = df_metric[df_metric['param_sim_options'].apply(lambda x: x['user_based'] == is_user_based)]
        
        plt.plot(df_final['param_k'], df_final['mean_test_rmse'], 
                 marker=markers[is_user_based], 
                 color=colors[metric], 
                 linestyle='-' if is_user_based else '--', 
                 label=f'{metric.upper()} ({labels_dict[is_user_based]})')

plt.title('Zależność błędu RMSE od liczby sąsiadów (k) dla różnych miar i podejść')
plt.xlabel('Liczba sąsiadów (k)')
plt.ylabel('Średni błąd RMSE (Cross-Validation)')
# Wyrzucamy legendę lekko poza wykres, żeby nie zasłaniała danych
plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
plt.grid(True, linestyle=':', alpha=0.7)
plt.tight_layout() # Zapobiega ucięciu legendy przy zapisie
plt.savefig('wykres_strojenie_k.png', dpi=300)
plt.close()

# Wykres 2: Porównanie końcowe algorytmów (tylko zbiór testowy)
labels = ['Zoptymalizowany kNN', 'Top Rated']
rmse_scores = [0.9786, 1.0285] # Zaktualizowane wartości testowe z ostatniego odpalenia
mae_scores = [0.7726, 0.8195]

x = np.arange(len(labels))
width = 0.35

fig, ax = plt.subplots(figsize=(8, 6))
rects1 = ax.bar(x - width/2, rmse_scores, width, label='RMSE', color='#4C72B0')
rects2 = ax.bar(x + width/2, mae_scores, width, label='MAE', color='#55A868')

ax.set_ylabel('Wartość błędu')
ax.set_title('Porównanie błędów na zbiorze testowym')
ax.set_xticks(x)
ax.set_xticklabels(labels)
ax.legend(loc='lower right')

# Dodawanie wartości nad słupkami
for rect in rects1 + rects2:
    height = rect.get_height()
    ax.annotate(f'{height:.4f}',
                xy=(rect.get_x() + rect.get_width() / 2, height),
                xytext=(0, 3),
                textcoords="offset points",
                ha='center', va='bottom')

plt.ylim(0, 1.2)
plt.savefig('wykres_porownanie.png', dpi=300, bbox_inches='tight')
plt.close()

print("Wygenerowano wykresy")