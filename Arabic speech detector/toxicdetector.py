from flask import Flask, request, jsonify
from flask_cors import CORS
from transformers import XLMRobertaTokenizer, XLMRobertaForSequenceClassification
import torch


app = Flask(__name__)
CORS(app)
# Load model once at startup


model_name = "akhooli/xlm-r-large-arabic-toxic"
tokenizer = XLMRobertaTokenizer.from_pretrained(model_name)
model = XLMRobertaForSequenceClassification.from_pretrained(model_name)


labels = ['non-toxic', 'toxic']

def predict_toxicity(text):
    inputs = tokenizer(text, return_tensors="pt", truncation=True, padding=True)
    with torch.no_grad():
        outputs = model(**inputs)
        probs = torch.nn.functional.softmax(outputs.logits, dim=-1).squeeze()
    return {labels[i]: float(probs[i]) for i in range(len(labels))}

@app.route("/analyze", methods=["POST"])
def analyze():
    data = request.get_json()
    text = data.get("text", "")

    if not text:
        return jsonify({"error": "No text provided"}), 400

    result = predict_toxicity(text)
    is_toxic = result.get("toxic", 0) > 0.5
    return jsonify({
        "input": text,
        "result": result,
        "toxic": is_toxic
    })

if __name__ == "__main__":
    app.run(debug=True)
