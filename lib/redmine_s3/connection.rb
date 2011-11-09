require 'aws-sdk'
module RedmineS3
  class Connection
    @@access_key_id     = nil
    @@secret_acces_key  = nil
    @@bucket            = nil
    @@conn              = nil
    
    class << self
      def load_options
        options = YAML::load( File.open(File.join(Rails.root, 'config', 's3.yml')) )
        @@access_key_id      = options[Rails.env]['access_key_id']
        @@secret_access_key  = options[Rails.env]['secret_access_key']
        @@bucket             = options[Rails.env]['bucket']
        @@endpoint           = options[Rails.env]['endpoint']
        @@private            = options[Rails.env]['private']
        @@expires            = options[Rails.env]['expires']
        @@secure             = options[Rails.env]['secure']
      end

      def establish_connection
        load_options unless @@access_key_id && @@secret_access_key
        options = {
          :access_key_id => @@access_key_id,
          :secret_access_key => @@secret_access_key
        }
        options[:s3_endpoint] = @@endpoint unless @@endpoint.nil?
        @conn = AWS::S3.new(options)
      end

      def conn
        @@conn || establish_connection
      end

      def bucket
        load_options unless @@bucket
        @@bucket
      end

      def create_bucket
        bucket = self.conn.buckets[@@bucket]
        bucket.create unless bucket.exists?
      end
      
      def private?
        !!@@private
      end

      def secure?
        !!@@secure
      end

      def put(filename, data)
        objects = self.conn.buckets[@@bucket].objects
        object = objects[filename]
        object = objects.create(filename) unless object.exists?
        options = {}
        options[:acl] = :public_read unless self.private?
        object.write(data, options)
      end

      def delete(filename)
        object = self.conn.buckets[@@bucket].objects[filename]
        object.delete if object.exists?
      end

      def object_url(filename)
        object = self.conn.buckets[@@bucket].objects[filename]
        if self.private?
          options = {:secure => self.secure?}
          options[:expires] = @@expires unless @@expires.nil?
          object.url_for(:read, options).to_s
        else
          object.public_url(:secure => self.secure?).to_s
        end
      end
    end
  end
end
