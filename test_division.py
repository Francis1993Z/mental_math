import random
from collections import Counter

def generate_division_pairs(min_val, max_val, n):
    """Reproduit l'algorithme Dart pour générer des paires de division."""
    results = []
    
    # Build list of valid (a, b) pairs
    valid_pairs = []
    for divisor in range(max(1, min_val), max_val + 1):
        for quotient in range(min_val, max_val + 1):
            dividend = divisor * quotient
            if min_val <= dividend <= max_val:
                valid_pairs.append((dividend, divisor))
    
    print(f"Paires valides trouvées: {len(valid_pairs)}")
    print(f"Liste des paires: {valid_pairs}\n")
    
    # Generate n random picks
    for _ in range(n):
        if valid_pairs:
            pair = random.choice(valid_pairs)
            results.append(pair)
        else:
            results.append((min_val, 1))
    
    return results

def analyze_results(results):
    """Analyse la distribution des résultats."""
    a_counter = Counter(r[0] for r in results)
    b_counter = Counter(r[1] for r in results)
    pair_counter = Counter(results)
    same_ab = sum(1 for a, b in results if a == b)
    
    print("=" * 50)
    print("STATISTIQUES")
    print("=" * 50)
    
    print(f"\nTotal questions: {len(results)}")
    print(f"Cas où a == b: {same_ab} ({100*same_ab/len(results):.1f}%)")
    
    print("\n--- Distribution de A (dividende) ---")
    for val, count in sorted(a_counter.items()):
        pct = 100 * count / len(results)
        bar = "█" * int(pct / 2)
        print(f"  {val:3d}: {count:4d} ({pct:5.1f}%) {bar}")
    
    print("\n--- Distribution de B (diviseur) ---")
    for val, count in sorted(b_counter.items()):
        pct = 100 * count / len(results)
        bar = "█" * int(pct / 2)
        print(f"  {val:3d}: {count:4d} ({pct:5.1f}%) {bar}")
    
    print("\n--- Top 10 paires les plus fréquentes ---")
    for (a, b), count in pair_counter.most_common(10):
        pct = 100 * count / len(results)
        print(f"  {a:2d} ÷ {b:2d} = {a//b:2d}  : {count:4d} ({pct:5.1f}%)")

def main():
    print("Test de l'algorithme de génération de divisions")
    print("-" * 50)
    
    min_val = int(input("Valeur minimum (ex: 1): ") or "1")
    max_val = int(input("Valeur maximum (ex: 10): ") or "10")
    n = int(input("Nombre de questions à générer (ex: 1000): ") or "1000")
    
    print(f"\nGénération de {n} divisions avec plage [{min_val}, {max_val}]...\n")
    
    results = generate_division_pairs(min_val, max_val, n)
    analyze_results(results)

if __name__ == "__main__":
    main()
