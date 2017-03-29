require 'aws-sdk'

class Ec2Client
  REGION = 'ap-northeast-1'
  AVAILABILITY_ZONE = 'ap-northeast-1b'

  def initialize
    @ec2 = Aws::EC2::Client.new(region: REGION)
  end

  def spot_price_histories
    values = {
      start_time: 30.days.ago.iso8601,
      end_time: Time.zone.now.iso8601,
      instance_types: %w(t2.large),
      product_descriptions: %w[Linux/UNIX (Amazon VPC)],
      availability_zone: AVAILABILITY_ZONE,
      max_results: 100
    }
    @ec2.describe_spot_price_history(values).spot_price_history.map { |h| [h[:timestamp], h[:spot_price]] }
  end
end
