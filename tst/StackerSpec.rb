
require "../src/Stacker.rb"


describe Stacker do

  after(:each) do
    FileUtils.rm_rf('images')
  end

  it "should be able to create image sets" do

    stacker = Stacker.new <<-EOF
      image_set {
        image :soup do
        end

        image :sauce do
        end
      }
    EOF

    stacker.create

    expect(File.directory?("images/soup")).to be true
    expect(File.exists?("images/soup/Dockerfile")).to be true
    expect(File.directory?("images/sauce")).to be true
    expect(File.exists?("images/sauce/Dockerfile")).to be true
  end

end
