from flask import Flask, request, jsonify
import csv
from flask_cors import CORS # permite o acesso web sobre origem

app = Flask(__name__)
CORS(app)

# Carrega os dados do CSV
operadoras = []
with open("Relatorio_cadop.csv", encoding="utf-8") as f:
    reader = csv.DictReader(f, delimiter=";")
    operadoras = list(reader)

@app.route("/buscar", methods=["GET"])
def buscar():
    termo = request.args.get("query", "").lower()
    resultados = [op for op in operadoras if termo in op["Nome_Fantasia"].lower()]
    return jsonify(resultados)

if __name__ == "__main__":
    app.run(debug=True)
