import seaborn as sns
import matplotlib.pyplot as plt
import matplotlib as mpl
from sklearn.linear_model import LinearRegression
import numpy as np
import argh

def plot_array(array_filename, xlabel, ylabel, ylim_low, ylim_high, dpi=200, regression=False):
    sns.set()

    Y = eval(open(array_filename).read())
    
    mpl.rcParams['figure.dpi'] = dpi

    plt.plot(Y)

    if regression:
        X = np.arange(0, len(Y)).reshape(-1, 1)
        lr = LinearRegression().fit(X, Y)
        plt.plot(X, lr.predict(X))
    
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.ylim(float(ylim_low), float(ylim_high))
    plt.show()

if __name__ == "__main__":
    argh.dispatch_command(plot_array)
