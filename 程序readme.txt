最终选用的数据是IEEE118_V4里的ESS2.0/G2.0
出清模型
1. 读入数据（火电、储能、需求、拓扑），增加储能的尾SOC和块报价参数
2. 进行第一次出请（此处要修改尾SOC，块报价），得到出清结果
3. 计算第一次出清的社会福利，要注意考虑块报价和尾部SOC的valuation
4. 计算没有所有储能时的出清，得到出清结果、社会福利、节点电价
5. 计算各储能的alpha（用两次的节点电价 * 出清结果），进行分配
6. 计算各储能的真实VCG，也就是它退出市场后的情况（其他储能依旧参与市场）
7. 计算fairness index
其中2、4、6其实可以合在一起，都是一个出清函数，3、4、6也可以合在一起，都是计算社会福利

这点是为了体现激励相容
然后，为了说明储能可能会在LMP乱报价，可以给予3不同的输入；为了说明储能在VCG激励相容，可以给予4-6不同的输入
然后发现，它的利润变大，社会福利变小

为了体现申报机制的好处
需要修改optimal bidding 模型，包含self-scheduling和申报价格

self-scheduling显然无法体现尾部SOC的区别，而且可能会削峰填谷错误，最后导致社会福利减小

申报价格，可以体现尾部SOC的区别，但是，可能在有些情况下不可行，所以它要保证在所有情况下都是可行的
（这个也必须是价格接收者）

输入的需求数据，最好也有所变化

ESS_main。由于这里是IC/BB的权衡，所以其实出清结果不变的。


Picture_agent12是用来画图，展现机制要素的设计效果。这部分结果对应的放在240128_newBidding里。这里只有agent1/2被当做研究对象。
这个结果是利用程序main_S_compare_bidding形成的
画图是？利用S_replot_data来画的

main_ESSmechanism_V6是用来泡基础的VCG的

240129反映了这个时候不同谎报达成的福利/利润等，对比了VCG/LMP/kIC_choose=0.1的场景），这部分结果放在Picture_newICver里。这里应该是所有的Agent被当做研究对象。
   这个是利用最外层的函数，S_temp_alltestIC这个循环函数，查看不同的SOC谎报幅度和不同的cost谎报幅度下的结果，然后里面调用main_ESSmechanism_Pareto_testIC【这个虽然可以涵盖main_ESSmechanism_Pareto，但看起来太复杂太复杂。这个是后来强行拿进来合用的，和falsebidding一起拿来合用的。不过算一次pareto并不复杂，只涉及到结算函数，所以设立就让他算了】
   S_ICtest_compare就可以把各路结果用来汇总
   展现不同ic下的利润情况。不同IC对应的策略不同，达成的社会福利也不同。

在   S_ICtest_compare这里不仅可以画图，还可以直接获取我们需要的数据


用main_ESSmechanism_Pareto画Pareto曲线

% 这里想要看它在真实申报的背景下，在LMP.VCG.kIC机制下能获取的收益/BB情况。这个也在main_ESSmechanism_Pareto_testIC这里看。看的时候用True cost看即可。True cost里包含了所有Pareto的信息

