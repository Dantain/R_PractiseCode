library(reshape)

#reshape包中的函数提供了解决汇总问题的统一办法，该包的核心思想是创造一个“熔化”的数据集版本(通过melt函数)，
#然后将其投入(cast函数)到一个所希望的目标对象中。通过melt函数“熔化”一个数据框、列表或数组，
#首先需要将变量分成编号变量和分析变量。默认情况下，该函数将因子和整数值变量设为编号变量，其余变量为分析变量。

#metl函数语法：
#1）熔化一个数据框：id.vars指定编号变量，measure.vars指定分析变量
melt(data, id.vars, measure.vars,
     variable_name = "variable", na.rm = !preserve.na, preserve.na = TRUE, ...)
#2）熔化一个数组
melt(data, varnames = names(dimnames(data)), ...)
#3）熔化一个列表
melt(data, ..., level=1)

#case应用：采用的数据为R自带的数据集state.x77、iris及随机数生成的数据框
#生成美国50个州的人口、收入的数据
states <- data.frame(state = row.names(state.x77),region = state.region,
                     state.x77,row.names = 1:50)
#采用melt函数熔化数据框(states)
m_states <- melt(states)#在不指定编号变量时，melt会显示被自动转为编号变量的变量名称
#可以通过id.vars和measure.vars参数指定感兴趣的分析变量和分组变量
head(melt(states,id.vars = 'state',measure.vars = 'Income'))
#注：上面的“熔化”数据，除了指定的或默认的id变量，还会额外产生variable变量和value变量，这两个变量分别存放感兴趣的分析变量名称和实际的数值



#通过melt函数，将数据框“熔化”后放入cast函数进行统计汇总。cast函数语法如下：
cast(data, formula = ... ~ variable, fun.aggregate=NULL, ...,
     margins=FALSE, subset=TRUE, df=FALSE, fill=NULL, add.missing=FALSE,
     value = guess_value(data))
#其中data为一个“熔化”后的对象；formula为显式公式，公式左边代表输出结果的行变量，右边则代表输出结果的列变量；
#fun.aggregate为汇总函数，默认情况下使用length,最关键的是该参数可以指定一个自编函数。

#case应用：计算按地区分组的每个变量的均值
reg_mean1 <- cast(m_states,region~variable,mean)
reg_mean2 <- cast(m_states,variable~region,mean)



#接下来，创建一个自编函数应用到cast函数中，本次使用到的数据集为iris
fun <- function(x) {
  require('fBasics')
  n = sum(!is.na(x))
  nmiss = sum(is.na(x))
  m = mean(x,na.rm = TRUE)
  s = sd(x,na.rm = TRUE)
  max = max(x,na.rm = TRUE)
  min = min(x,na.rm = TRUE)
  range = max-min
  skew = skewness(x,na.rm = TRUE)
  kurto = kurtosis(x,na.rm = TRUE)
  return(c(n = n,nmiss = nmiss,mean = m,sd = s,max = max,min = min,
           range = range,skewness = skew,kurtosis = kurto))
}
#数据“熔化”与汇总
m_iris <- melt(iris)
#为了方便版面显示，这里将输出结果设置为列表格式(注意，我在variable前面加了.|)
library(fBasics)
summary_result <- cast(m_iris,variable~.|Species,fun)
#如果想选择特定的分析变量，可以通过subset参数实现,一般与%in%联合使用。a%in%b 表示a的元素是否为b的子集
#分析Sepal.Length变量的汇总信息
sl_summary <- cast(m_iris,Species~variable,fun,subset = variable %in% 'Sepal.Length')


#对于多个变量的分组统计，cast函数中显式公式的左边或右边用+连接多个分组变量
#应用：使用随机数函数生成泊松分布的离散变量
#模拟数据的生成
data <- data.frame(x = rpois(100,2),y = rpois(100,3),z = runif(100,10,20))
#数据“熔化”
m_data <- melt(data,measure.vars = 'z')
#多变量分组统计 
summary_data <- cast(m_data,x + y ~ variable, c(mean,min,max,median))#注：表达式左边的最后一个变量是变化最快的
#最后再介绍cast函数中显式公式的几种变形：
#以y的每一个值单独成一个列，统计x分组下的汇总值
reshape1 <- cast(m_data,x~y+variable,mean) #这里的NaN表示x和y的组合下没有z的值
#用竖线(|)隔开variable和y,返回列表形式，y值为列表的元素，元素内容又以x分组统计
reshape2 <- cast(m_data,x~variable|y,mean) 
