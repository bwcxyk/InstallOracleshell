create or replace procedure ctas_par(p_tab        in varchar2, --需要被分区表名称
                                     p_part_colum in varchar2, --需要被分区列名称
                                     p_part_nums  in number default 24, --需要建立的分区月数
                                     p_tablespace in varchar2) as

  /*

   功能： 实现普通表到分区表的ctas建表语句提取

    参数含义：
      p_tab in varchar2,                 -----------------需要进行分区的普通表的表名
      p_part_colum in varchar2,          -----------------需要分区的列，本程序主要针对最常见的时间范围类型分区，按月份分区
      p_part_nums in number default 24,  -----------------默认情况下为最近一个月到后续24个月，可以自行选择
      p_tablespace IN VARCHAR2           -----------------分区表的表空间

    执行方法：
       set serveroutput on size 1000000
       exec ctas_par(p_tab => 'ts_real_datatrance', p_part_colum => 'trans_date',p_part_nums=> 24,p_tablespace => 'TBS_BOSSWG');

  */

  yyyymmdd    varchar2(50) := to_char(trunc(sysdate),
                                      'dd');
  v_sql       varchar2(32767);
  v_min_date  date;
  v_first_day date;
  v_next_day  date;
  v_prev_day  date;
  v_partiton  varchar2(1000);
  v_partitons varchar2(32767);
begin
  --获取需要被分区的分区列最早记录的日期
  v_sql := 'select min(' || p_part_colum || ') from ' || p_tab;
  execute immediate (v_sql)
    into v_min_date;

  dbms_output.put_line('分区表获取分区列最小记录日期：' || v_min_date);

  --获取分区表开始的下个月份
  select to_date(to_char(v_min_date,
                         'yyyymm') || '01',
                 'yyyymmdd')
    into v_first_day
    from dual;

  --通过循环组合partition分区的格式
  for i in 1 .. p_part_nums
  loop
    select add_months(v_first_day,
                      i)
      into v_next_day
      from dual;
    select add_months(v_next_day,
                      -1)
      into v_prev_day
      from dual;
    v_partiton  := 'partition ' || p_tab || '_P' || to_char(v_prev_day,
                                                            'yyyymm') || ' values less than (TO_DATE(''' ||
                   to_char(v_next_day,
                           'SYYYY-MM-DD HH24:MI:SS') || ''', ''SYYYY-MM-DD HH24:MI:SS'', ''NLS_CALENDAR=GREGORIAN'')) tablespace ' || p_tablespace || ',' ||
                   chr(13) || chr(10);
    v_partitons := v_partitons || v_partiton;
  end loop;

  v_sql := 'create table ' || p_tab || chr(13) || chr(10) || 'partition BY RANGE(' || p_part_colum || ')(' || chr(13) || chr(10) || v_partitons ||
           'partition ' || p_tab || '_MAX values less than (maxvalue) tablespace ' || p_tablespace || ')
             nologging
             parallel 4
             enable row movement
             tablespace ' || p_tablespace || '
             as select /*+parallel(t,8)*/ * from ' || p_tab || '_' || yyyymmdd || ' t where 1 = 2;' || chr(13) || chr(10);

  v_sql := v_sql || ' alter table ' || p_tab || ' logging;
 ' || chr(13) || chr(10);

  v_sql := v_sql || ' alter table ' || p_tab || ' noparalle; ';

  dbms_output.put_line('分区表ctas创建的完整语句如下： ');
  dbms_output.put_line(v_sql);
end ctas_par;
/