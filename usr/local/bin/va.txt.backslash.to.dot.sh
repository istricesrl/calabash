#!/bin/bash

# restituisco la stringa passata come parametro con i backslash sostituiti da punto
echo -n $1 | sed -e 's/^\///' | sed -e 's#/$##' | tr '/' '.'
