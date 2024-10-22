`define LOG(FMT) \
    log_inner(`__FILE__, $sformatf FMT)

