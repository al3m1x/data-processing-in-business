# 1. Automatyczna dekompozycja szeregu (model addytywny)
dekompozycja <- decompose(ts_power, type = "additive")

# 2. Zapisanie wykresu klasycznej dekompozycji do pliku
png("part3-dekompozycja.png", width=800, height=800, res=120)
plot(dekompozycja)
title(main="Dekompozycja addytywna zużycia energii elektrycznej", line=2)
dev.off()

# 3. Zastosowanie algorytmu STL (nie ucina brzegów szeregu)
dekompozycja_stl <- stl(ts_power, s.window = "periodic")

# 4. Zapisanie wykresu nowej dekompozycji STL do osobnego pliku
png("part3-stl.png", width=800, height=800, res=120)
plot(dekompozycja_stl, main="Dekompozycja STL zużycia energii elektrycznej")
dev.off()
cat("Zapisano wykresy dekompozycji do plików part3-dekompozycja.png oraz part3-stl.png\n")