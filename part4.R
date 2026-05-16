library(forecast)
library(ggplot2)

cat("--- BUDOWA MODELU ARIMA Z PODZIAŁEM TRAIN/TEST ---\n")

# 1. Podział na zbiór uczący (Train) i testowy (Test)
horyzont <- 30
n <- length(ts_power)
# Train: wszystko oprócz ostatnich 30 dni
train <- subset(ts_power, end = n - horyzont)
# Test: tylko ostatnie 30 dni (ukryte przed modelem)
test <- subset(ts_power, start = n - horyzont + 1)

# 2. Trening modelu TYLKO na zbiorze uczącym
model_train <- auto.arima(train, seasonal = TRUE)
print(summary(model_train))

# 3. Analiza reszt (zapis wykresów do pliku)
png("part4-residuals.png", width=800, height=600, res=120)
checkresiduals(model_train)
dev.off()

# Wykonanie i wypisanie formalnego testu Ljung-Boxa
cat("\n--- TEST LJUNG-BOXA ---\n")
print(checkresiduals(model_train, plot=FALSE))

# 4. Wygenerowanie prognozy dla ukrytego okresu (30 dni)
prognoza <- forecast(model_train, h = horyzont)

# 5. Wykres z nałożonymi rzeczywistymi danymi i "zoomem" na końcówkę
png("part4-forecast-overlay.png", width=1000, height=600, res=120)

# Obliczamy punkt startowy do przybliżenia wykresu (ok. 100 dni przed końcem)
czas_start_zoom <- time(ts_power)[n - 100]
czas_koniec <- time(ts_power)[n]

wykres_overlay <- autoplot(prognoza) +
  autolayer(test, series="Rzeczywiste zużycie", color="red", linewidth=0.8) +
  coord_cartesian(xlim = c(czas_start_zoom, czas_koniec)) + # Zoom na końcówkę
  labs(title="Weryfikacja modelu ARIMA na zbiorze testowym (ostatnie 30 dni)",
       x="Czas (lata / cykle)", 
       y="Średnia dzienna moc czynna [kW]") +
  theme_minimal() +
  theme(legend.position="bottom")

print(wykres_overlay)
dev.off()

cat("\nZapisano wykres weryfikacyjny do pliku part4-forecast-overlay.png\n")