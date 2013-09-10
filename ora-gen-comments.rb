require 'oci8'

# Change these values before running the script.
$parameters = {
  user: 		'user',
  password: 'password',
  tnsname:  'LOCAL',
  out_file: 'comments.sql'
}

def get_connection(user, password, tnsname)
  begin
    puts 'Connecting...'
    conn = OCI8.new user, password, tnsname 
    puts 'Connected.'
  rescue StandardError => message 
    $stderr.print "Connection failed: #{message}"
    conn = nil
  end
  conn
end

def generate_template(conn)
	cursor = conn.exec "select table_name, comments from user_tab_comments" 
  while row = cursor.fetch
    generate_table conn, row[0], row[1]
  end
  cursor.close
end

def generate_table(conn, table_name, comment)
	puts "Generating comments for #{table_name}"
	comment ||= ''
	write_line "\ncomment on table #{table_name} is '#{comment}';\n"	
	cursor = conn.exec "select column_name, comments from user_col_comments where table_name = '#{table_name}'" 
  while row = cursor.fetch
    generate_column table_name, row[0], row[1]
  end
  cursor.close
end

def generate_column(table_name, column_name, comment)
	write_line "comment on column #{table_name}.#{column_name} is '#{comment}';\n"	
end

def write_line(line)
  File.open($parameters[:out_file], 'a') {|file| file.puts line}
end

def main
	conn = get_connection $parameters[:user], $parameters[:password], $parameters[:tnsname]
  return if conn.nil?
  File.open $parameters[:out_file], 'w' # Will create if it doesn't exist.
  generate_template conn
  conn.logoff
  puts 'Disconnected.'
end

main

__END__
