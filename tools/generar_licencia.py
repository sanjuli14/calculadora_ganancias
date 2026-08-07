# -*- coding: utf-8 -*-
# Generador de códigos de licencia para "Cuentas Claras"
# Uso: python3 generar_licencia.py ID_DISPOSITIVO
# Ejemplo: python3 generar_licencia.py 7F3K-X9QD
import sys
import hashlib
import random
import string

SALT = "CC-SALT-2026"


def generar_codigo():
    alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    return "".join(random.SystemRandom().choice(alphabet) for _ in range(12))


def hash_licencia(codigo, device_id):
    return hashlib.sha256(f"{SALT}:{device_id}:{codigo}".encode()).hexdigest()


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Falta el ID del dispositivo.")
        print("Uso: python3 generar_licencia.py ID_DISPOSITIVO")
        sys.exit(1)

    device_id = sys.argv[1].strip().upper()
    codigo = generar_codigo()
    h = hash_licencia(codigo, device_id)

    print("=" * 50)
    print("ID de dispositivo :", device_id)
    print("CODIGO DEL CLIENTE:", codigo)
    print("Hash (para el Gist):", h)
    print("=" * 50)
    print()
    print("1) Envia el CODIGO al cliente (solo funciona en su dispositivo).")
    print("2) Agrega este hash a tu Gist en clients.json:")
    print('   {"clients": ["<hash>", ...]}')
