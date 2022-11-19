require('fastcsv')
require('daru')
require 'tempfile'

# File handler helps to convert into different data format
class FileHandler
  attr_reader :handler

  def initialize(handler:)
    @handler = handler
  end


  # Emits temporary file absolute path
  def download(remote_path)
    @handler.download(remote_path)
  end
end
