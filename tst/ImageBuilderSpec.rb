
require "../src/ImageBuilder.rb"


describe ImageBuilder do

  after(:each) do
    FileUtils.rm_rf('images')
  end

  it "should create a directory for docker image definitions" do
    create_image :soup do
    end

    expect(File.directory?("images/soup")).to be true
  end

  it "should create a docker file inside the image definition directory" do
    create_image :soup do
    end

    expect(File.exists?("images/soup/Dockerfile")).to be true
  end

  it "should create a FROM instruction into the Dockerfile" do
    create_image :soup do
      from :ubuntu
    end

    expected = <<-EOF
      FROM ubuntu
    EOF

    expect(File.read("images/soup/Dockerfile")).to eq expected.strip_heredoc

  end

  it "should create a RUN instruction into the Dockerfile" do
    create_image :soup do
      from :ubuntu
      run "echo \"Hello Soup\""
    end

    expected = <<-EOF
      FROM ubuntu
      RUN echo "Hello Soup"
    EOF

    expect(File.read("images/soup/Dockerfile")).to eq expected.strip_heredoc

  end

  it "should create multiple RUN instructions using one run cmd as string" do
    create_image :soup do
      from :ubuntu
      run <<-EOF
        echo "Hello Soup"
        echo "Should be good"
      EOF
    end

    expected = <<-EOF
      FROM ubuntu
      RUN echo "Hello Soup"
      RUN echo "Should be good"
    EOF

    expect(File.read("images/soup/Dockerfile")).to eq expected.strip_heredoc

  end

  it "should create multiple RUN instructions using one run code block" do
    create_image :soup do
      from :ubuntu
      run {
        echo "Hello Soup"
        echo "Should be good"
        echo 42
      }
    end

    expected = <<-EOF
      FROM ubuntu
      RUN echo "Hello Soup"
      RUN echo "Should be good"
      RUN echo 42
    EOF

    expect(File.read("images/soup/Dockerfile")).to eq expected.strip_heredoc

  end

  it "should create files and add them as copy instructions to the Dockerfile" do
    create_image :soup do
      from :ubuntu

      file "/tmp/soup.txt", <<-EOF
      EOF

      # Soup on Sunday: http://allpoetry.com/poem/8981159-Soup-on-Sunday--by-suecat
      #
      file "soup.txt", <<-EOF
        Bacon bone aroma
        from open fridge door.
        Tonight warm fire,
        steaming bowl,
        home-made pea soup.
      EOF
    end

    expected = <<-EOF
      FROM ubuntu
      COPY ./tmp/soup.txt /tmp/soup.txt
      COPY soup.txt soup.txt
    EOF

    expect(File.read("images/soup/Dockerfile")).to eq expected.strip_heredoc
    expect(File.exists?("images/soup/tmp/soup.txt")).to be true
    expect(File.exists?("images/soup/soup.txt")).to be true

    expected = "Bacon bone aroma\nfrom open fridge door.\nTonight warm fire,\nsteaming bowl,\nhome-made pea soup.\n"

    expect(File.read("images/soup/soup.txt")).to eq expected.strip_heredoc
  end

  it "should create ENV instructions based on a hasmap" do
    create_image :soup do
      from :ubuntu
      env { 
        host  "http://soup.com" 
        port  1972
        debug
      }
    end

    expected = <<-EOF
      FROM ubuntu
      ENV host="http://soup.com"
      ENV port="1972"
      ENV debug="true"
    EOF

    expect(File.read("images/soup/Dockerfile")).to eq expected.strip_heredoc
  end

  it "should create ENV instructions that use variables set by other ENV instructions" do
    create_image :soup do
      from :ubuntu
      env { 
        proxy  "soup.com" 
        http_proxy "http://#{proxy}"
        https_proxy "https://#{proxy}"
      }
    end

    expected = <<-EOF
      FROM ubuntu
      ENV proxy="soup.com"
      ENV http_proxy="http://soup.com"
      ENV https_proxy="https://soup.com"
    EOF

    expect(File.read("images/soup/Dockerfile")).to eq expected.strip_heredoc
  end

  it "should allow hidden variables in ENV setup" do
    create_image :soup do
      from :ubuntu
      env { 
        _proxy  "soup.com" 
        http_proxy "http://#{_proxy}"
        https_proxy "https://#{_proxy}"
      }
    end

    expected = <<-EOF
      FROM ubuntu
      ENV http_proxy="http://soup.com"
      ENV https_proxy="https://soup.com"
    EOF

    expect(File.read("images/soup/Dockerfile")).to eq expected.strip_heredoc
  end

  it "should allow ENV vars that start with un underscore by using two underscores" do
    create_image :soup do
      from :ubuntu
      env { 
        __proxy  "soup.com" 
        ___a  "b"
      }
    end

    expected = <<-EOF
      FROM ubuntu
      ENV _proxy="soup.com"
      ENV __a="b"
    EOF

    expect(File.read("images/soup/Dockerfile")).to eq expected.strip_heredoc
  end

  it "should allow env section refer to variable declared in previous env sections" do
    create_image :soup do
      from :ubuntu
      env { 
        proxy  "soup.com" 
      }
      env {
        http_proxy "http://#{proxy}"
        https_proxy "https://#{proxy}"
      }
    end

    expected = <<-EOF
      FROM ubuntu
      ENV proxy="soup.com"
      ENV http_proxy="http://soup.com"
      ENV https_proxy="https://soup.com"
    EOF

    expect(File.read("images/soup/Dockerfile")).to eq expected.strip_heredoc
  end

  it "should use env variable substitution in file creation" do
    create_image :soup do
      from :ubuntu
      env { 
        url  "http://allpoetry.com/poem/8981159-Soup-on-Sunday--by-suecat" 
      }
      file "soup.txt", <<-EOF
        click #{url} to read the poem
      EOF
    end

    expected = "click http://allpoetry.com/poem/8981159-Soup-on-Sunday--by-suecat to read the poem\n"

    expect(File.read("images/soup/soup.txt")).to eq expected.strip_heredoc
  end
 


  it "should create and copy an executable startup file, and run it as entrypoint" do
    create_image :soup do
      from :ubuntu

      start "/tmp/startup.sh", <<-EOF
        #!/bin/bash
        top
      EOF
    end

    expected = <<-EOF
      FROM ubuntu
      COPY ./tmp/startup.sh /tmp/startup.sh
      RUN chmod +x /tmp/startup.sh
      ENTRYPOINT exec /tmp/startup.sh
    EOF

    expect(File.read("images/soup/Dockerfile")).to eq expected.strip_heredoc
    expect(File.exists?("images/soup/tmp/startup.sh")).to be true
    expect(File.read("images/soup/tmp/startup.sh")).to eq "#!/bin/bash\ntop\n"
  end


end
