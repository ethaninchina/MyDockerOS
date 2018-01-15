# coding: utf-8
"""命令行火车余票查询器
Usage:
    tickets [-gdtkz] <from> <to> <date>

Options:
    -h,--help   显示帮助菜单
    -g          高铁
    -d          动车
    -t          特快
    -k          快速
    -z          直达
"""
import requests
from docopt import docopt
import stations
from prettytable import PrettyTable #使信息以好看的表格形式呈现出来
from colorama import init,Fore   #这个可以设置颜色
headers={
        'User-Agent':'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.101 Safari/537.36'
        }

init() #colorama进行初始化
def cli():
    arguments = docopt(__doc__)#用docopt来解析参数
    from_station=stations.get_telecode(arguments.get('<from>'))
    to_station=stations.get_telecode(arguments.get('<to>'))
    date=arguments.get('<date>')
    options=''.join([key for key,value in arguments.items() if value is True])
    #构造请求地址
    url=('https://kyfw.12306.cn/otn/leftTicket/queryZ?'
         'leftTicketDTO.train_date={}&'
         'leftTicketDTO.from_station={}&'
         'leftTicketDTO.to_station={}&'
         'purpose_codes=ADULT').format(date,from_station,to_station)
    r=requests.get(url,verify=False,headers=headers)
    r.encoding=r.apparent_encoding
    if (r.text.find('网络可能存在问题') != -1):
        print('网络存在问题，请重试,可能是你访问的过于频繁！')
        exit()
    #requests里面自带了json解析器，所以我们可以用来解析python
    raw_trains=r.json()['data']['result']   #原始火车信息
    pt=PrettyTable() #初始化一个prettytable对象
    pt._set_field_names('车次 车站 时间 历时 一等座 二等座 软卧 硬卧 硬座 无座'.split())
    for raw_train in raw_trains:                   #对每一趟列车进行解析
        data_list=raw_train.split('|')
        train_no=data_list[3]
        initial=train_no[0].lower()  #获取首字母,表示车次
        if not options or initial in options:   #如果没有设置options或者首字母在options里面
            from_station_code=data_list[6]
            to_station_code=data_list[7]
            start_time=data_list[8]
            arrive_time=data_list[9]
            time_duration=data_list[10]
            first_class_seat=data_list[31] if data_list[31] else '--'
            second_class_seat=data_list[30] if data_list[30] else '--'
            soft_sleep=data_list[23] if data_list[23] else '--'
            hard_sleep=data_list[28] if data_list[28] else '--'
            hard_seat=data_list[29] if data_list[29] else '--'
            no_seat=data_list[26] if data_list[26] else '--'
            pt.add_row([
                        Fore.YELLOW + train_no + Fore.RESET,
                        '\n'.join([
                            Fore.GREEN + stations.get_name(from_station_code) + Fore.RESET,
                            Fore.RED + stations.get_name(to_station_code) + Fore.RESET]),
                        '\n'.join([
                            Fore.GREEN + start_time + Fore.RESET,
                            Fore.RED + arrive_time + Fore.RESET]),
                        time_duration,
                        first_class_seat,
                        second_class_seat,
                        soft_sleep,
                        hard_sleep,
                        hard_seat,
                        no_seat])
    print(pt)

if __name__ == '__main__':
    cli()
