import seaborn as sns
import matplotlib.pyplot as plt
import matplotlib as mpl
import numpy as np
import argh

def plot_array(array_filename, xlabel, ylabel, ylim_low, ylim_high, dpi=200, regression=False):
    sns.set()

    file_content = open(array_filename).read().replace('\n', '')
    Y = eval(file_content)
    X = np.arange(len(Y))
    
    mpl.rcParams['figure.dpi'] = dpi

    plt.plot(Y, 'x')

    if regression:
        A = np.vstack([X, np.ones(len(X))]).T
        m, c = np.linalg.lstsq(A, Y, rcond=None)[0]
        plt.plot(X, m * X + c, lw=3)
    
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.ylim(float(ylim_low), float(ylim_high))
    plt.show()

if __name__ == "__main__":
    argh.dispatch_command(plot_array)
