# AWS Lambda layers

Simple bash script to create layers to be used in AWS Lambda. At the moment the script has been tested with Python and NodeJS.

## Usage

`./create_layer <LAYER_NAME> <RUNTIME_AND_VERSION>`

Example:

- `./create_layer.sh pypdf2 python:3.9`
- `./create_layer.sh axios nodejs:18`