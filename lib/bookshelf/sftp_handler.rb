require('net/sftp')
require('tempfile')

# This helps to handle SFTP file
class SftpHandler
  def download(remote_path)
    tempfile = Tempfile.new

    connection do |conn|
      conn.download!(remote_path, tempfile.path)
    end

    tempfile.path
  end

  def connection
    Net::SFTP.start(ENV['SFTP_HOST'], ENV['SFTP_USERNAME'], password: ENV['SFTP_PASSWORD'], port: ENV['SFTP_PORT']) do |sftp|
      yield(sftp)
    end
  end
end
