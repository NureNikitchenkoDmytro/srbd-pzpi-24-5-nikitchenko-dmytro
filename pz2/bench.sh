#!/usr/bin/env bash
# ПЗ2. Прогін трьох запитів варіанта для кожної конфігурації індексів.
# Знімає logical reads і elapsed time з SET STATISTICS IO/TIME.
# Запуск: bash pz2/bench.sh   (з теки ~/nure/srbd, контейнер має бути піднятий)
set -u
SQL="docker compose exec -T mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P SrbdLab2026! -C -d TestDB"

Q1="SELECT Id, Label, Quantity FROM Goods WHERE Quantity < 100;"
Q2="SELECT Id, Label FROM Goods WHERE Price > 100.0 AND InputDate = CAST(GETDATE() AS date);"
Q3="SELECT InputDate, SUM(Quantity) AS [Count] FROM Goods GROUP BY InputDate;"

run_query() { # $1 = текст запиту
  local out
  out=$($SQL -Q "SET NOCOUNT ON; SET STATISTICS IO ON; SET STATISTICS TIME ON; $1" 2>&1)
  local reads elapsed
  reads=$(echo "$out" | grep -o 'logical reads [0-9]*' | awk '{s+=$3} END {print s+0}')
  elapsed=$(echo "$out" | grep -o 'elapsed time = [0-9]* ms' | tail -1 | grep -o '[0-9]*')
  echo "${reads};${elapsed:-0}"
}

config() { # $1 = назва, $2 = DDL
  $SQL -i /scripts/pz2/04_cleanup.sql >/dev/null 2>&1
  [ -n "$2" ] && $SQL -Q "$2" >/dev/null 2>&1
  $SQL -Q "CHECKPOINT;" >/dev/null 2>&1
  local r=""
  for q in "$Q1" "$Q2" "$Q3"; do
    run_query "$q" >/dev/null      # прогрів
    r="$r$(run_query "$q")|"
  done
  printf '%-52s %s\n' "$1" "$r"
}

printf '%-52s %s\n' "Конфігурація" "Q1 reads;ms | Q2 reads;ms | Q3 reads;ms"
config "Без індексів (купа)" ""
config "ix_goods_quantity (Quantity) INCL (Id,Label)" \
  "CREATE NONCLUSTERED INDEX ix_goods_quantity ON Goods (Quantity) INCLUDE (Id, Label);"
config "ix_goods_date_price (InputDate,Price) INCL (Id,Label)" \
  "CREATE NONCLUSTERED INDEX ix_goods_date_price ON Goods (InputDate, Price) INCLUDE (Id, Label);"
config "ix_goods_date_qty (InputDate) INCL (Quantity)" \
  "CREATE NONCLUSTERED INDEX ix_goods_date_qty ON Goods (InputDate) INCLUDE (Quantity);"
config "cix_goods_id (Id) - кластеризований" \
  "CREATE UNIQUE CLUSTERED INDEX cix_goods_id ON Goods (Id);"
config "Сукупність: cix_goods_id + 3 некластеризованих" \
  "CREATE UNIQUE CLUSTERED INDEX cix_goods_id ON Goods (Id);
   CREATE NONCLUSTERED INDEX ix_goods_quantity ON Goods (Quantity) INCLUDE (Id, Label);
   CREATE NONCLUSTERED INDEX ix_goods_date_price ON Goods (InputDate, Price) INCLUDE (Id, Label);
   CREATE NONCLUSTERED INDEX ix_goods_date_qty ON Goods (InputDate) INCLUDE (Quantity);"
