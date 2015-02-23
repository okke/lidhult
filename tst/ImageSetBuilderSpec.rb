

require "../src/ImageSetBuilder.rb"


describe ImageSetBuilder do

  after(:each) do
    FileUtils.rm_rf('images')
  end

  it "should be able to create images" do

    create_image_set do
      image :soup do
      end

      image :sauce do
      end
    end

    expect(File.directory?("images/soup")).to be true
    expect(File.exists?("images/soup/Dockerfile")).to be true
    expect(File.directory?("images/sauce")).to be true
    expect(File.exists?("images/sauce/Dockerfile")).to be true
  end

  it "should give images access to their parents environment" do

    create_image_set do
      image :soup do
        env {
          temperature 95
        }
      end

      image :pea_soup do
        from :soup

        file "soup.txt", <<-EOF
          Please serve at #{temperature} degrees celcius.
        EOF
      end
    end

    expected = "Please serve at 95 degrees celcius.\n"

    expect(File.read("images/pea_soup/soup.txt")).to eq expected.strip_heredoc

  end

  it "should use a declared namespace for the directory where image definitions are generated" do
    create_image_set :myspace do
      image :soup do
      end
    end

    expect(File.directory?("images/myspace")).to be true
    expect(File.exists?("images/myspace/soup/Dockerfile")).to be true
  end

  it "should use a declared namespace for references to images" do

    create_image_set :myspace do
      image :base do
      end
      image :soup do
        from :base
      end
    end

    expected = <<-EOF
      FROM myspace/base
    EOF

    expect(File.read("images/myspace/soup/Dockerfile")).to eq expected.strip_heredoc
  end

  it "should not use a declared namespace for images not declared as symbol" do

    create_image_set :myspace do

      image :base do
        from "ubuntu"
      end
    end

    expected = <<-EOF
      FROM ubuntu
    EOF

    expect(File.read("images/myspace/base/Dockerfile")).to eq expected.strip_heredoc
  end

  it "should generate a docker build script" do

    create_image_set do

      image :base do
      end

      image :soup do
        from :base
      end
    end

    expected = <<-EOF
      #!/bin/bash
      docker build -t "base" images/base
      docker build -t "soup" images/soup
    EOF

    expect(File.read("images/build.sh")).to eq expected.strip_heredoc
    expect(File.executable?("images/build.sh")).to be true

  end

  it "should use the declared namespace as docker build script" do

    create_image_set :myspace do
      image :base do
      end
    end

    expect(File.read("images/build_myspace.sh")).to eq expected.strip_heredoc
    expect(File.executable?("images/build_myspace.sh")).to be true

  end

end

