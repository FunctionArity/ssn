if defined?(Rails::Console) || defined?(Rails::Server)
  require "amazing_print"


  AmazingPrint.defaults = {
    indent: 2,
    index: false,
    multiline: true,
    plain: true
  }
end
