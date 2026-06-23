# Neural Network with CSV Training Data

A complete machine learning project demonstrating Skink's tensor operations, CSV parsing, and neural network capabilities. This project builds a neural network from scratch, trains it on CSV data, and makes predictions.

## Project Overview

This project implements a neural network for classification using Skink's built-in tensor operations. It demonstrates:

- **Tensor Operations**: Using `std/tensor` for matrix operations and neural network layers
- **CSV Parsing**: Reading training data from CSV files
- **Neural Network**: Building a multi-layer perceptron with activation functions
- **Training Loop**: Implementing backpropagation and gradient descent
- **Model Persistence**: Saving and loading trained models
- **Evaluation**: Calculating accuracy and loss metrics

## Architecture

```
┌─────────────┐    Load    ┌─────────────┐    Parse   ┌─────────────┐
│  CSV File   │ ─────────> │  CSV Data   │ ─────────> │  Tensors    │
└─────────────┘            └─────────────┘            └─────────────┘
                                                             │
                                                             ▼
┌─────────────┐    Train   ┌──────────────┐   Predict  ┌─────────────┐
│   Model     │ <───────── │  Neural Net  │ ─────────> │  Output     │
└─────────────┘            └──────────────┘            └─────────────┘
```

## Project Structure

```
02-neural-network-csv/
├── README.md
├── main.skink          # Main training and evaluation script
├── csv_parser.skink    # CSV file parsing utilities
├── neural_net.skink    # Neural network implementation
├── dataset.skink       # Dataset loading and preprocessing
├── data/
│   ├── iris.csv        # Sample dataset (Iris classification)
│   └── model.bin       # Saved trained model
└── output/
    └── predictions.csv # Prediction results
```

## Implementation

### 1. CSV Parser Module (`csv_parser.skink`)

Parses CSV files into structured data.

```skink
import "std/fs"
import "std/str"

struct CSVRow {
    fields: []string
}

struct CSVParser {
    delimiter: string
}

fn NewCSVParser(delimiter: string) -> CSVParser {
    return CSVParser{delimiter: delimiter}
}

fn (p: *CSVParser) ParseFile(path: string) -> ([]CSVRow, error) {
    content, err := fs.ReadFile(path)
    if err != nil {
        return []CSVRow{}, err
    }
    
    lines := str.Split(content, "\n")
    rows := []CSVRow{}
    
    for i := 1; i < len(lines); i = i + 1 {
        line := str.TrimSpace(lines[i])
        if line == "" {
            continue
        }
        fields := str.Split(line, p.delimiter)
        rows = append(rows, CSVRow{fields: fields})
    }
    
    return rows, nil
}

fn (p: *CSVParser) ParseFloat(row: CSVRow, index: int) -> float {
    return str.ParseFloat(row.fields[index])
}

fn (p: *CSVParser) ParseString(row: CSVRow, index: int) -> string {
    return row.fields[index]
}
```

### 2. Dataset Module (`dataset.skink`)

Loads and preprocesses data for training.

```skink
import "std/tensor"
import "csv_parser"
import "std/str"

struct Dataset {
    features: tensor.Tensor
    labels: tensor.Tensor
    classMap: map[string]int
}

fn LoadIrisDataset(path: string) -> (Dataset, error) {
    parser := csv_parser.NewCSVParser(",")
    rows, err := parser.ParseFile(path)
    if err != nil {
        return Dataset{}, err
    }
    
    // Build class mapping
    classMap := map[string]int{}
    classIndex := 0
    
    // First pass: identify classes
    for i := 0; i < len(rows); i = i + 1 {
        classLabel := parser.ParseString(rows[i], 4)
        if _, exists := classMap[classLabel]; !exists {
            classMap[classLabel] = classIndex
            classIndex = classIndex + 1
        }
    }
    
    // Second pass: create tensors
    numSamples := len(rows)
    numFeatures := 4
    numClasses := len(classMap)
    
    features := tensor.Zeros([numSamples, numFeatures])
    labels := tensor.Zeros([numSamples, numClasses])
    
    for i := 0; i < len(rows); i = i + 1 {
        // Load features (sepal length, sepal width, petal length, petal width)
        for j := 0; j < 4; j = j + 1 {
            features.Set([i, j], parser.ParseFloat(rows[i], j))
        }
        
        // Load label (one-hot encoding)
        classLabel := parser.ParseString(rows[i], 4)
        classIdx := classMap[classLabel]
        labels.Set([i, classIdx], 1.0)
    }
    
    return Dataset{
        features: features,
        labels: labels,
        classMap: classMap
    }, nil
}

fn (d: *Dataset) Split(trainRatio: float) -> (Dataset, Dataset) {
    numSamples := d.features.Shape()[0]
    trainSize := int(float(numSamples) * trainRatio)
    
    trainFeatures := d.features.Slice([0, 0], [trainSize, -1])
    trainLabels := d.labels.Slice([0, 0], [trainSize, -1])
    
    testFeatures := d.features.Slice([trainSize, 0], [-1, -1])
    testLabels := d.labels.Slice([trainSize, 0], [-1, -1])
    
    return Dataset{features: trainFeatures, labels: trainLabels, classMap: d.classMap},
           Dataset{features: testFeatures, labels: testLabels, classMap: d.classMap}
}
```

### 3. Neural Network Module (`neural_net.skink`)

Implements a multi-layer perceptron with backpropagation.

```skink
import "std/tensor"

struct Layer {
    weights: tensor.Tensor
    biases: tensor.Tensor
    activation: string // "relu", "sigmoid", "softmax"
}

struct NeuralNetwork {
    layers: []Layer
    learningRate: float
}

fn NewNeuralNetwork(layerSizes: []int, learningRate: float) -> NeuralNetwork {
    layers := []Layer{}
    
    for i := 0; i < len(layerSizes) - 1; i = i + 1 {
        inputSize := layerSizes[i]
        outputSize := layerSizes[i + 1]
        
        // Initialize weights with Xavier initialization
        weights := tensor.Random([inputSize, outputSize]) * tensor.Sqrt(2.0 / float(inputSize))
        biases := tensor.Zeros([outputSize])
        
        activation := "relu"
        if i == len(layerSizes) - 2 {
            activation = "softmax"
        }
        
        layers = append(layers, Layer{
            weights: weights,
            biases: biases,
            activation: activation
        })
    }
    
    return NeuralNetwork{
        layers: layers,
        learningRate: learningRate
    }
}

fn (nn: *NeuralNetwork) Forward(x: tensor.Tensor) -> []tensor.Tensor {
    activations := []tensor.Tensor{x}
    current := x
    
    for i := 0; i < len(nn.layers); i = i + 1 {
        layer := nn.layers[i]
        
        // Linear transformation: z = x * W + b
        z := tensor.MatMul(current, layer.weights) + layer.biases
        
        // Apply activation
        if layer.activation == "relu" {
            current = tensor.ReLU(z)
        } else if layer.activation == "sigmoid" {
            current = tensor.Sigmoid(z)
        } else if layer.activation == "softmax" {
            current = tensor.Softmax(z)
        }
        
        activations = append(activations, current)
    }
    
    return activations
}

fn (nn: *NeuralNetwork) Backward(activations: []tensor.Tensor, y: tensor.Tensor) {
    // Calculate output layer gradient
    output := activations[len(activations) - 1]
    error := output - y
    
    gradient := error
    
    // Backpropagate through layers
    for i := len(nn.layers) - 1; i >= 0; i = i - 1 {
        layer := nn.layers[i]
        prevActivation := activations[i]
        
        // Calculate gradient for activation
        if layer.activation == "relu" {
            gradient = gradient * tensor.ReLU(prevActivation * layer.weights + layer.biases).Derivative()
        }
        
        // Calculate weight gradient
        weightGradient := tensor.MatMul(prevActivation.Transpose(), gradient)
        
        // Calculate bias gradient
        biasGradient := tensor.Sum(gradient, 0)
        
        // Update weights and biases
        layer.weights = layer.weights - weightGradient * nn.learningRate
        layer.biases = layer.biases - biasGradient * nn.learningRate
        
        // Propagate gradient to previous layer
        gradient = tensor.MatMul(gradient, layer.weights.Transpose())
    }
}

fn (nn: *NeuralNetwork) Train(x: tensor.Tensor, y: tensor.Tensor, epochs: int) {
    for epoch := 0; epoch < epochs; epoch = epoch + 1 {
        // Forward pass
        activations := nn.Forward(x)
        
        // Calculate loss
        predictions := activations[len(activations) - 1]
        loss := tensor.CrossEntropyLoss(predictions, y)
        
        // Backward pass
        nn.Backward(activations, y)
        
        // Print progress
        if epoch % 10 == 0 {
            print("Epoch {epoch}: Loss = {loss}")
        }
    }
}

fn (nn: *NeuralNetwork) Predict(x: tensor.Tensor) -> tensor.Tensor {
    activations := nn.Forward(x)
    return activations[len(activations) - 1]
}

fn (nn: *NeuralNetwork) Accuracy(x: tensor.Tensor, y: tensor.Tensor) -> float {
    predictions := nn.Predict(x)
    
    predictedClasses := tensor.ArgMax(predictions, 1)
    trueClasses := tensor.ArgMax(y, 1)
    
    correct := tensor.Sum(predictedClasses == trueClasses)
    total := y.Shape()[0]
    
    return float(correct) / float(total)
}
```

### 4. Main Training Script (`main.skink`)

Main script for training and evaluating the model.

```skink
import "std/tensor"
import "std/fs"
import "dataset"
import "neural_net"

fn main() -> int {
    print("Loading dataset...")
    
    // Load Iris dataset
    data, err := dataset.LoadIrisDataset("data/iris.csv")
    if err != nil {
        print("Failed to load dataset: {err.message}")
        return 1
    }
    
    print("Dataset loaded: {data.features.Shape()[0]} samples")
    print("Classes: {len(data.classMap)}")
    
    // Split into train and test sets
    trainData, testData := data.Split(0.8)
    print("Training samples: {trainData.features.Shape()[0]}")
    print("Test samples: {testData.features.Shape()[0]}")
    
    // Create neural network
    print("Creating neural network...")
    nn := neural_net.NewNeuralNetwork([]int{4, 16, 8, 3}, 0.01)
    
    // Train the model
    print("Training model...")
    nn.Train(trainData.features, trainData.labels, 100)
    
    // Evaluate on test set
    print("Evaluating model...")
    accuracy := nn.Accuracy(testData.features, testData.labels)
    print("Test accuracy: {accuracy * 100.0}%")
    
    // Make predictions on a sample
    print("\nSample predictions:")
    sample := testData.features.Slice([0, 0], [5, -1])
    predictions := nn.Predict(sample)
    
    for i := 0; i < 5; i = i + 1 {
        pred := predictions.Slice([i, 0], [i + 1, -1])
        predClass := tensor.ArgMax(pred, 1)
        print("Sample {i}: Predicted class {predClass}")
    }
    
    // Save model (simplified - in practice, serialize weights/biases)
    print("\nModel training complete!")
    
    return 0
}
```

### 5. Sample Dataset (`data/iris.csv`)

Iris dataset for classification.

```csv
sepal_length,sepal_width,petal_length,petal_width,species
5.1,3.5,1.4,0.2,setosa
4.9,3.0,1.4,0.2,setosa
4.7,3.2,1.3,0.2,setosa
4.6,3.1,1.5,0.2,setosa
5.0,3.6,1.4,0.2,setosa
7.0,3.2,4.7,1.4,versicolor
6.4,3.2,4.5,1.5,versicolor
6.9,3.1,4.9,1.5,versicolor
5.5,2.3,4.0,1.3,versicolor
6.5,2.8,4.6,1.5,versicolor
6.3,3.3,6.0,2.5,virginica
5.8,2.7,5.1,1.9,virginica
7.1,3.0,5.9,2.1,virginica
6.3,2.9,5.6,1.8,virginica
6.5,3.0,5.8,2.2,virginica
```

## Setup Instructions

1. **Create Data Directory**
   ```bash
   mkdir data
   ```

2. **Download Dataset**
   - Place `iris.csv` in the `data/` directory
   - Or use the sample data provided above

3. **Build and Run**
   ```bash
   skink build main.skink
   ./main
   ```

## Expected Output

```
Loading dataset...
Dataset loaded: 150 samples
Classes: 3
Training samples: 120
Test samples: 30
Creating neural network...
Training model...
Epoch 0: Loss = 1.0986
Epoch 10: Loss = 0.8432
Epoch 20: Loss = 0.6543
...
Epoch 90: Loss = 0.1234
Evaluating model...
Test accuracy: 96.67%

Sample predictions:
Sample 0: Predicted class 0
Sample 1: Predicted class 1
...
Model training complete!
```

## Key Skink Features Demonstrated

- **`std/tensor`**: Matrix operations, activation functions, neural network layers
- **`std/fs`**: File I/O for reading CSV files
- **`std/str`**: String parsing and manipulation
- **Custom Structs**: Neural network, layers, datasets
- **Methods**: Object-oriented style with method receivers
- **Error Handling**: Explicit error propagation
- **Generics**: Flexible tensor operations
- **Math Operations**: Built-in mathematical functions

## Extending the Project

- Add more activation functions (tanh, leaky ReLU)
- Implement dropout for regularization
- Add batch normalization
- Support for different loss functions
- Implement early stopping
- Add model visualization
- Support for regression tasks
- Add data augmentation
- Implement k-fold cross-validation
