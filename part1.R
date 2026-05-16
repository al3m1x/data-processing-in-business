# 1. Deklaracja "importów" - niezbędne do działania funkcji
library(dplyr)
library(lubridate)
library(ggplot2)

# 2. Wczytanie surowego zbioru danych z pliku (plik musi być w folderze roboczym R)
cat("Wczytywanie danych... To może potrwać kilka-kilkanaście sekund.\n")
df <- read.csv("household_power_consumption.txt", sep=";", na.strings="?", stringsAsFactors=FALSE)

# 3. Przetwarzanie formatu daty na rozpoznawalny przez R
df$Date <- dmy(df$Date)

# 4. Agregacja do poziomu dziennego (teraz operator %>% zadziała bez problemu)
df_daily <- df %>%
  group_by(Date) %>%
  summarise(Daily_Global_Active_Power = mean(Global_active_power, na.rm = TRUE))

# Odrzucamy dni z pustymi danymi
df_daily <- na.omit(df_daily)

# Sprawdzenie i wypisanie dokładnych dat początkowych i końcowych
data_poczatkowa <- min(df_daily$Date)
data_koncowa <- max(df_daily$Date)
cat("Początek danych:", format(data_poczatkowa, "%Y-%m-%d"), "\n")
cat("Koniec danych:", format(data_koncowa, "%Y-%m-%d"), "\n")

# 5. Generowanie wykresu szeregu czasowego z wymuszoną osią X
wykres <- ggplot(df_daily, aes(x = Date, y = Daily_Global_Active_Power)) +
  geom_line(color = "darkblue", linewidth = 0.5) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") + # Wymuszenie równych lat na osi
  labs(title = sprintf("Średnie dzienne zużycie energii elektrycznej (%s do %s)", 
                       format(data_poczatkowa, "%Y"), format(data_koncowa, "%Y")),
       subtitle = "Zagregowane dane z 1-minutowych pomiarów w gospodarstwie domowym",
       x = "Data",
       y = "Średnia moc czynna [kW]",
       caption = "Źródło: UCI Machine Learning Repository") +
  theme_minimal()

# Wyświetlenie wykresu w środowisku
print(wykres)

# 6. Automatyczny zapis poprawionego wykresu do pliku
ggsave("part1-photo.png", plot = wykres, width = 8, height = 5, dpi = 300)
cat("Zapisano wykres do pliku part1-photo.png\n")