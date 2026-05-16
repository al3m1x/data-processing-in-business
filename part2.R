library(dplyr)
library(lubridate)
library(tseries)

# 1. Konwersja na szereg czasowy (zakładamy, że ramka df_daily z Części 1 jest w pamięci)
cat("Czy df_daily$Daily_Global_Active_Power to ts?:", is.ts(df_daily$Daily_Global_Active_Power), "\n")
ts_power <- ts(df_daily$Daily_Global_Active_Power, frequency = 365)
cat("Czy ts_power to ts?:", is.ts(ts_power), "\n\n")

# 2. Zapis wykresu pudełkowego (wskaźnik zmienności / anomalie) do pliku
png("part2-boxplot.png", width=800, height=600, res=120)
boxplot(ts_power, main="Wykres pudełkowy - detekcja anomalii i zmienność", 
        ylab="Średnia dzienna moc czynna [kW]", col="lightblue")
dev.off()

# 3. Składowa stała i zmienność
srednia <- mean(ts_power)
odchylenie <- sd(ts_power)
wsp_zmiennosci <- (odchylenie / srednia) * 100

cat("--- WSKAŹNIKI STATYSTYCZNE ---\n")
cat("Składowa stała (średnia):", round(srednia, 2), "kW\n")
cat("Zmienność (Odch. std.):", round(odchylenie, 2), "kW\n")
cat("Współczynnik zmienności (CV):", round(wsp_zmiennosci, 2), "%\n\n")

# 4. Dynamika (indeksy łańcuchowe)
dynamika <- (ts_power[-1] / ts_power[-length(ts_power)]) * 100
srednia_dynamika <- mean(dynamika)
cat("--- DYNAMIKA ---\n")
cat("Średnie tempo zmian (dzień do dnia):", round(srednia_dynamika, 2), "%\n\n")

# 5. Stacjonarność (Rozszerzony test Dickeya-Fullera)
cat("--- TEST STACJONARNOŚCI (ADF) ---\n")
print(adf.test(ts_power, alternative = "stationary"))