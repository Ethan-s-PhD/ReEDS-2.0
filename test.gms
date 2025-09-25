$title Filter & Mapping Demo

*--------------*
* 1. Sets
*--------------*
set i "all technologies"
/ nuclear_stor1
  nuclear_stor2
  battery_4
  tes_ms6
  nuclear
/;

* Subsets
set nuclear_stor(i) / nuclear_stor1, nuclear_stor2 /;
set storage(i)      / battery_4, tes_ms6 /;
set nuclear_only(i) / nuclear /;

alias(i,i2,i_store);

*--------------*
* 2. Mapping set: hybrid nuclear+storage tech -> storage tech
* (You can think of this as nuclear_stor_stortech(i_hybrid, i_storage))
*--------------*
set nuclear_stor_stortech(i,i)
    / nuclear_stor1.battery_4
      nuclear_stor2.tes_ms6 /;

* Display to see which pairs are YES
display nuclear_stor_stortech;

*--------------*
* 3. Sample time set & simple cost data
*--------------*
set t / y2025, y2030 /;

parameter cost_cap(i,t) "dummy capital cost (2004$/MW)";
cost_cap("battery_4","y2025") = 100;
cost_cap("battery_4","y2030") =  90;
cost_cap("tes_ms6"  ,"y2025") = 130;
cost_cap("tes_ms6"  ,"y2030") = 110;
cost_cap("nuclear"  ,"y2025") = 6000;
cost_cap("nuclear"  ,"y2030") = 5800;

display cost_cap;

*--------------*
* 4. Using a mapping set as a filter (lookup)
*--------------*
parameter storage_cost_from_map(i,t) "storage portion capex via mapping";

* For each hybrid i (outer loop implied by LHS) sum over storage techs i_store
storage_cost_from_map(i,t)$nuclear_stor(i) =
    sum{i_store$ nuclear_stor_stortech(i,i_store), cost_cap(i_store,t)};

display nuclear_stor_stortech;
parameter map_flag(i,i) ;
map_flag(i,i_store) = i_store$nuclear_stor_stortech(i,i_store);
display map_flag;
display storage_cost_from_map;

*--------------*
* 5. Equivalent double-index version (if mapping had config dimension)
* (Here we fake a config set identical to hybrid names)
*--------------*
set nuclear_stor_config / nuclear_stor1, nuclear_stor2 /;

* A config->storage mapping (mirrors earlier but via config)
set ns_cfg_stortech(nuclear_stor_config,i) / nuclear_stor1.battery_4, nuclear_stor2.tes_ms6 /;

parameter storage_cost_via_config(i,t);

storage_cost_via_config(i,t)$nuclear_stor(i) =
    sum{(nuclear_stor_config,i_store)$[ sameas(i,nuclear_stor_config)
                                       $ ns_cfg_stortech(nuclear_stor_config,i_store)],
        cost_cap(i_store,t)};

display storage_cost_via_config;

*--------------*
* 6. Showing sameas() behavior
*--------------*
parameter sameas_flag(i,nuclear_stor_config);
sameas_flag(i,nuclear_stor_config) = sameas(i,nuclear_stor_config);
display sameas_flag;

*--------------*
* 7. Two equivalent sum syntaxes
*--------------*
parameter demo1(i) "filter on index list";
parameter demo2(i) "filter on summand";

demo1(i)$nuclear_stor(i) = sum{i_store$ nuclear_stor_stortech(i,i_store), 1};
demo2(i)$nuclear_stor(i) = sum{i_store, 1$ nuclear_stor_stortech(i,i_store)};

display demo1, demo2;

*--------------*
* 8. Guarding against multiple matches (example)
*--------------*
parameter storage_cost_safe(i,t);

storage_cost_safe(i,t)$nuclear_stor(i) =
    sum{i_store$ nuclear_stor_stortech(i,i_store), cost_cap(i_store,t)}
  / max(1, sum{i_store$ nuclear_stor_stortech(i,i_store), 1});

display storage_cost_safe;

*--------------*
* 9. Demonstrate that unused pairs are zero by creating a dense matrix
*--------------*
parameter map_matrix(i,i_store);
map_matrix(i,i_store) = nuclear_stor_stortech(i,i_store);
display map_matrix;

*--------------*
* 10. Putting nuclear + storage together (toy formula)
* total hybrid cost = nuclear cost + mapped storage cost
*--------------*
parameter hybrid_total(i,t);

hybrid_total(i,t)$nuclear_stor(i) =
    cost_cap("nuclear",t) + storage_cost_from_map(i,t);

display hybrid_total;

abort$(card(hybrid_total)=0) "No hybrid totals computed: check sets.";