# -*- coding: utf-8 -*-
# Generador de códigos de licencia para "Cuentas Claras"
# Uso: python3 generar_licencia.py ID_DISPOSITIVO [NOMBRE_CLIENTE]
# Ejemplo: python3 generar_licencia.py 7F3K-X9QD "Panaderia La Esquina"
import sys
import hashlib
import random

SALT = "CC-SALT-2026"


def generar_codigo():
    alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    return "".join(random.SystemRandom().choice(alphabet) for _ in range(12))


def hash_licencia(codigo, device_id):
    return hashlib.sha256(f"{SALT}:{device_id}:{codigo}".encode()).hexdigest()


def formato_json(entradas):
    """Genera el bloque JSON para pegar en tu Gist."""
    if all(n is None for n, _ in entradas):
        return '{"clients": [' + ", ".join(f'"{h}"' for _, h in entradas) + "]}"
    return '{"clients": [' + ", ".join(
        f'{{"name": "{n}", "hash": "{h}"}}' if n else f'"{h}"'
        for n, h in entradas
    ) + "]}"


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Falta el ID del dispositivo.")
        print("Uso: python3 generar_licencia.py ID_DISPOSITIVO [NOMBRE_CLIENTE]")
        sys.exit(1)

    device_id = sys.argv[1].strip().upper()
    nombre = sys.argv[2].strip() if len(sys.argv) > 2 else None

    # Modo mantenimiento: permite ver el hash de un codigo existente
    # python3 generar_licencia.py ID CODIGO --ver
    if len(sys.argv) > 3 and sys.argv[3] == "--ver":
        codigo = sys.argv[2].strip()
        h = hash_licencia(codigo, device_id)
        print("=" * 50)
        print("ID de dispositivo :", device_id)
        print("CODIGO           :", codigo)
        print("Hash (para el Gist):", h)
        print("=" * 50)
        sys.exit(0)

    codigo = generar_codigo()
    h = hash_licencia(codigo, device_id)

    print("=" * 50)
    print("ID de dispositivo :", device_id)
    if nombre:
        print("Cliente          :", nombre)
    print("CODIGO DEL CLIENTE:", codigo)
    print("Hash (para el Gist):", h)
    print("=" * 50)
    print()
    print("1) Envia el CODIGO al cliente (solo funciona en su dispositivo).")
    print("2) Agrega este hash a tu Gist en clients.json:")
    if nombre:
        print(f'   {{"name": "{nombre}", "hash": "{h}"}}')
    else:
        print(f'   {{"name": "NOMBRE_OPCIONAL", "hash": "{h}"}}')
    print()
    print("Si varios clientes van en el mismo Gist, lista completa:")
    print("   " + formato_json([(nombre, h)]))
    print()
    print("Pista: para ver el hash de un codigo ya generado usa:")
    print("   python3 generar_licencia.py ID CODIGO --ver")
