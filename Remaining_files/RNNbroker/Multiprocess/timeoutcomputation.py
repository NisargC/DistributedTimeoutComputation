"""This file is responsible for computing the next timeout based on past data of timeouts
It makes use of a Convoluted LSTM whose details can be found at:
https://papers.nips.cc/paper/5955-convolutional-lstm-network-a-machine-learning-approach-for-precipitation-nowcasting.pdf
Some data preprocessing is done to ensure that the data is in the format that the Recurrent Neural Network expects.
"""

__version__ = '1.1'
__author__ = 'Nisarg Chokshi'

from tensorflow.keras.utils import plot_model
from tensorflow.keras.layers import TimeDistributed, MaxPooling1D, Flatten, Conv1D, ConvLSTM2D
from tensorflow.keras.optimizers import Adam
from numpy import array
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM
from tensorflow.keras.layers import Dense
import os
import matplotlib.pyplot as plt

os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'


# split a univariate sequence into samples
def split_sequence(raw_seq, n_steps):
    X, y = list(), list()
    for i in range(len(raw_seq)):
        # find the end of this pattern
        end_ix = i + n_steps
        # check if we are beyond the sequence
        if end_ix > len(raw_seq) - 1:
            break
        # gather input and output parts of the pattern
        seq_x, seq_y = raw_seq[i:end_ix], raw_seq[end_ix]
        X.append(seq_x)
        y.append(seq_y)
    return array(X), array(y)


# Generate a model and compute the timeout based on the raw data sequence received.
def computeTimeout(raw_seq):
    n_steps = 8

    test_seq = raw_seq[(-n_steps - 1): -1]
    del raw_seq[(-n_steps - 1):-1]

    X, y = split_sequence(raw_seq, n_steps)
    n_features = 1
    n_seq = 2
    n_steps = 4

    # reshape from [samples, timesteps] into [samples, subsequences, timesteps, features]
    X = X.reshape((X.shape[0], n_seq, 1, n_steps, n_features))
    # define model
    model = Sequential()
    model.add(
        ConvLSTM2D(filters=64*2, kernel_size=(1, 2), activation='relu', input_shape=(n_seq, 1, n_steps, n_features), return_sequences=True))
    model.add(Flatten())
    model.add(Dense(1))

    adam = Adam(learning_rate=0.008)
    model.compile(optimizer=adam, loss='mse')

    # fit model
    history = model.fit(X, y, epochs=100, verbose=0, use_multiprocessing=True, workers=16)
    # plt.plot(history.history['loss'])
    # plt.title('model loss')
    # plt.ylabel('loss')
    # plt.xlabel('epoch')
    # plt.legend(['train'], loc='upper left')
    # plt.show()
    # # plot_model(model,'model.png')

    x_input = array(test_seq)
    x_input = x_input.reshape((1, n_seq, 1, n_steps, n_features))
    yhat = model.predict(x_input, verbose=0)
    return yhat[0][0]
