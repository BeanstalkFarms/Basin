# Multi-block MEV Resistant Geometric EMA and Geometric Cumulative SMA and Pump

Given:
- $\alpha$ a parameter $\alpha \in (0,1)$
- $\gamma$ the maximum change permitted in each balance per block
- $\beta$ the block time in the given EVM

The pump tracks 3 different types of balances at the last updated timestamp $l$:
- multi-block MEV resistant last balances: $[ x_{0,l}^{MEV} , ..., x_{n,l}^{MEV}]$
- multi-block MEV resistant Geometric EMA: $[x_{0,l}^{EMA}, ..., x_{n,l}^{EMA}]$
- multi-block MEV-resistant Cumulative Geometric SMA: $[x_{0,l},^{SMA}, ..., x_{n,l}^{SMA}]$


## Update

The Pump is updated at timestamp $t$ with balances $[x_{0,t}, \cdots, x_{n,t}]$

### MEV-Resistant Last Balances

$$
x^{MEV}_{i,t} = 
\begin{cases}
min\left(log_2(x_{i,l}), x^{MEV}_{i,t-l} + log_2(1+\gamma) \frac{t-l}{\beta}\right) & log_2(x_{i,l}) > x^{MEV}_{i,t} \\
max\left(log_2(x_{i,l}), x^{MEV}_{i,t-l} + log_2(1-\gamma) \frac{t-l}{\beta}\right) & \text{otherwise} \\
\end{cases}
$$

### MEV-Resistant EMA Balances
$$
x^{EMA}_{i,t} = \alpha^{t-l} x^{EMA}_{i,l} + (1 - \alpha^{t-l}) x^{MEV}_{i,t}
$$

### MEV-Resistant Cumulative SMA Balances

$$
x^{SMA}_{i,t} = x^{SMA}_{i,l} + (t-l) x^{MEV}_{i,t}
$$

## Read

Given all balances are stored on-chain in the $log_2$ form, they need to be converted to their actual balances on read:

### MEV-Resistant Last Balances

$$
y^{MEV}_{i,t} = 2^{x^{MEV}_{i,t}}
$$

### MEV-Resistant EMA Balances
$$
y^{EMA}_{i,t} = 2^{x^{EMA}_{i,t}}
$$

### MEV-Resistant SMA Balances

$$
y^{SMA}_{i,l,t} = 2^{\frac{x^{SMA}_{i,t} - x^{SMA}_{i,l}}{t-l}}
$$
