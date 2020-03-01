require 'rails_helper'

RSpec.describe Formatter do
  let(:local_account)  { Fabricate(:account, domain: nil, username: 'alice') }
  let(:remote_account) { Fabricate(:account, domain: 'remote.test', username: 'bob', url: 'https://remote.test/') }

  shared_examples 'encode and link URLs' do
    context 'matches a stand-alone medium URL' do
      let(:text) { 'https://hackernoon.com/the-power-to-build-communities-a-response-to-mark-zuckerberg-3f2cac9148a4' }

      it 'has valid URL' do
        is_expected.to include 'href="https://hackernoon.com/the-power-to-build-communities-a-response-to-mark-zuckerberg-3f2cac9148a4"'
      end
    end

    context 'matches a stand-alone google URL' do
      let(:text) { 'http://google.com' }

      it 'has valid URL' do
        is_expected.to include 'href="http://google.com"'
      end
    end

    context 'matches a stand-alone IDN URL' do
      let(:text) { 'https://nic.みんな/' }

      it 'has valid URL' do
        is_expected.to include 'href="https://nic.みんな/"'
      end

      it 'has display URL' do
        is_expected.to include '<span class="">nic.みんな/</span>'
      end
    end

    context 'matches a URL without trailing period' do
      let(:text) { 'http://www.mcmansionhell.com/post/156408871451/50-states-of-mcmansion-hell-scottsdale-arizona. ' }

      it 'has valid URL' do
        is_expected.to include 'href="http://www.mcmansionhell.com/post/156408871451/50-states-of-mcmansion-hell-scottsdale-arizona"'
      end
    end

    context 'matches a URL without closing paranthesis' do
      let(:text) { '(http://google.com/)' }

      it 'has valid URL' do
        is_expected.to include 'href="http://google.com/"'
      end
    end

    context 'matches a URL without exclamation point' do
      let(:text) { 'http://www.google.com!' }

      it 'has valid URL' do
        is_expected.to include 'href="http://www.google.com"'
      end
    end

    context 'matches a URL without single quote' do
      let(:text) { "http://www.google.com'" }

      it 'has valid URL' do
        is_expected.to include 'href="http://www.google.com"'
      end
    end

    context 'matches a URL without angle brackets' do
      let(:text) { 'http://www.google.com>' }

      it 'has valid URL' do
        is_expected.to include 'href="http://www.google.com"'
      end
    end

    context 'matches a URL with a query string' do
      let(:text) { 'https://www.ruby-toolbox.com/search?utf8=%E2%9C%93&q=autolink' }

      it 'has valid URL' do
        is_expected.to include 'href="https://www.ruby-toolbox.com/search?utf8=%E2%9C%93&amp;q=autolink"'
      end
    end

    context 'matches a URL with parenthesis in it' do
      let(:text) { 'https://en.wikipedia.org/wiki/Diaspora_(software)' }

      it 'has valid URL' do
        is_expected.to include 'href="https://en.wikipedia.org/wiki/Diaspora_(software)"'
      end
    end

    context 'matches a URL with Japanese path string' do
      let(:text) { 'https://ja.wikipedia.org/wiki/日本' }

      it 'has valid URL' do
        is_expected.to include 'href="https://ja.wikipedia.org/wiki/日本"'
      end
    end

    context 'matches a URL with Korean path string' do
      let(:text) { 'https://ko.wikipedia.org/wiki/대한민국' }

      it 'has valid URL' do
        is_expected.to include 'href="https://ko.wikipedia.org/wiki/대한민국"'
      end
    end

    context 'matches a URL with Simplified Chinese path string' do
      let(:text) { 'https://baike.baidu.com/item/中华人民共和国' }

      it 'has valid URL' do
        is_expected.to include 'href="https://baike.baidu.com/item/中华人民共和国"'
      end
    end

    context 'matches a URL with Traditional Chinese path string' do
      let(:text) { 'https://zh.wikipedia.org/wiki/臺灣' }

      it 'has valid URL' do
        is_expected.to include 'href="https://zh.wikipedia.org/wiki/臺灣"'
      end
    end

    context 'contains unsafe URL (XSS attack, visible part)' do
      let(:text) { %q{http://example.com/b<del>b</del>} }

      it 'has escaped HTML' do
        is_expected.to include '&lt;del&gt;b&lt;/del&gt;'
      end
    end

    context 'contains unsafe URL (XSS attack, invisible part)' do
      let(:text) { %q{http://example.com/blahblahblahblah/a<script>alert("Hello")</script>} }

      it 'has escaped HTML' do
        is_expected.to include '&lt;script&gt;alert(&quot;Hello&quot;)&lt;/script&gt;'
      end
    end

    context 'contains HTML (script tag)' do
      let(:text) { '<script>alert("Hello")</script>' }

      it 'has escaped HTML' do
        is_expected.to include '<p>&lt;script&gt;alert(&quot;Hello&quot;)&lt;/script&gt;</p>'
      end
    end

    context 'contains HTML (XSS attack)' do
      let(:text) { %q{<img src="javascript:alert('XSS');">} }

      it 'has escaped HTML' do
        is_expected.to include '<p>&lt;img src=&quot;javascript:alert(&apos;XSS&apos;);&quot;&gt;</p>'
      end
    end

    context 'contains invalid URL' do
      let(:text) { 'http://www\.google\.com' }

      it 'has raw URL' do
        is_expected.to eq '<p>http://www\.google\.com</p>'
      end
    end

    context 'contains a hashtag' do
      let(:text)  { '#hashtag' }

      it 'has a link' do
        is_expected.to include '/tags/hashtag" class="mention hashtag" rel="tag">#<span>hashtag</span></a>'
      end
    end
  end

  describe '#format' do
    subject { Formatter.instance.format(status) }

    context 'with local status' do
      context 'with reblog' do
        let(:reblog) { Fabricate(:status, account: local_account, text: 'Hello world', uri: nil) }
        let(:status) { Fabricate(:status, reblog: reblog) }

        it 'returns original status with credit to its author' do
          is_expected.to include 'RT <span class="h-card"><a href="https://cb6e6126.ngrok.io/@alice" class="u-url mention">@<span>alice</span></a></span> Hello world'
        end
      end

      context 'contains plain text' do
        let(:status)  { Fabricate(:status, text: 'text', uri: nil) }

        it 'paragraphizes' do
          is_expected.to eq '<p>text</p>'
        end
      end

      context 'contains line feeds' do
        let(:status)  { Fabricate(:status, text: "line\nfeed", uri: nil) }

        it 'removes line feeds' do
          is_expected.not_to include "\n"
        end
      end

      context 'contains linkable mentions' do
        let(:status) { Fabricate(:status, mentions: [ Fabricate(:mention, account: local_account) ], text: '@alice') }

        it 'links' do
          is_expected.to include '<a href="https://cb6e6126.ngrok.io/@alice" class="u-url mention">@<span>alice</span></a></span>'
        end
      end

      context 'contains unlinkable mentions' do
        let(:status) { Fabricate(:status, text: '@alice', uri: nil) }

        it 'does not link' do
          is_expected.to include '@alice'
        end
      end

      describe 'code block' do
        let(:local_text) { nil }
        let(:status)  { Fabricate(:status, text: local_text, uri: nil) }

        context 'contains single line code block' do
          let(:local_text) { "`program`" }
          it 'has code block' do
            expect(subject).to match '<span><code class="inline">program</code></span>'
          end
        end

        context 'contains inline code with html tag' do
          let(:local_text) { "`<div>Hello</div>`" }
          it 'has code block' do
            expect(subject).to match '<span><code class="inline">&lt;div&gt;Hello&lt;/div&gt;</code></span>'
          end
        end

        context 'contains multiple inline code blocks' do
          let(:local_text) { "`hoge` `piyo`" }
          it 'has code block' do
            expect(subject).to match('<span><code class="inline">hoge</code></span> <span><code class="inline">piyo</code></span>')
          end
        end

        context 'contains multi line code block' do
          let(:local_text) { "```ruby\nputs 'Hello, World!'\n```" }
          it 'has code block' do
            expect(subject).to match '<p><code data-language="ruby">puts &#39;Hello, World!&#39;</code></p>'
          end
        end

        context 'contains multi line code block with filename' do
          let(:local_text) { "```ruby:hello.rb\nputs 'Hello, World!'\n```" }
          it 'has code block' do
            expect(subject).to match '<p><code data-language="ruby" data-filename="hello.rb">puts &#39;Hello, World!&#39;</code></p>'
          end
        end

        context 'contains code block with html tag' do
          let(:local_text) { "```\n<div>Hello</div>\n```" }
          it 'has code block' do
            expect(subject).to match '<p><code>&lt;div&gt;Hello&lt;/div&gt;</code></p>'
          end
        end

        context 'contains multiple code blocks' do
          let(:local_text) { "```ruby\nputs 'Hello, World!'\n```\n```js\nconsole.log('Hello, World!');\n```" }
          it 'has code block' do
            expect(subject).to include('<p><code data-language="ruby">puts &#39;Hello, World!&#39;</code></p>')
            expect(subject).to include('<p><code data-language="js">console.log(&#39;Hello, World!&#39;);</code></p>')
          end
        end

        context 'contains capture literals in code block' do
          let(:local_text) { '`\1`' }
          it 'has code block' do
            expect(subject).to include('<span><code class="inline">\1</code></span>')
          end
        end

        context '' do
          let(:local_text) { '[[[codeblock0]]]hoge[[[codeblock1]]]hoge[[[codeblock2]]]`hi`' }
          it 'has code block' do
            expect(subject).to include('<span><code class="inline">hi</code></span>')
          end
        end

        context 'contains a mention literal in the code block' do
          let(:status) { Fabricate(:status, mentions: [ Fabricate(:mention, account: local_account) ], text: local_text) }
          let(:local_text) { '@alice `@alice`' }

          before { local_account }

          it 'has code block and its mention is raw text' do
            expect(subject).to include('<span><code class="inline">@alice</code></span>')
          end
        end

        context 'contains a hashtag in the code block' do
          let(:local_text) { '`#ruby`' }

          before { local_account }

          it 'has code block and its mention is raw text' do
            expect(subject).to include('<span><code class="inline">#ruby</code></span>')
          end
        end

        context 'contains a link in the code block' do
          let(:local_text) { '`http://example.com`' }

          before { local_account }

          it 'has code block and its link is raw text' do
            expect(subject).to include('<span><code class="inline">http://example.com</code></span>')
          end
        end
      end

      context do
        subject do
          status = Fabricate(:status, text: text, uri: nil)
          Formatter.instance.format(status)
        end

        include_examples 'encode and link URLs'
      end

      context 'with custom_emojify option' do
        let!(:emoji) { Fabricate(:custom_emoji) }
        let(:status) { Fabricate(:status, account: local_account, text: text) }

        subject { Formatter.instance.format(status, custom_emojify: true) }

        context 'with emoji at the start' do
          let(:text) { ':coolcat: Beep boop' }

          it 'converts shortcode to image tag' do
            is_expected.to match(/<p><img draggable="false" class="emojione" alt=":coolcat:"/)
          end
        end

        context 'with emoji in the middle' do
          let(:text) { 'Beep :coolcat: boop' }

          it 'converts shortcode to image tag' do
            is_expected.to match(/Beep <img draggable="false" class="emojione" alt=":coolcat:"/)
          end
        end

        context 'with concatenated emoji' do
          let(:text) { ':coolcat::coolcat:' }

          it 'does not touch the shortcodes' do
            is_expected.to match(/:coolcat::coolcat:/)
          end
        end

        context 'with emoji at the end' do
          let(:text) { 'Beep boop :coolcat:' }

          it 'converts shortcode to image tag' do
            is_expected.to match(/boop <img draggable="false" class="emojione" alt=":coolcat:"/)
          end
        end
      end
    end

    context 'with remote status' do
      let(:status) { Fabricate(:status, account: remote_account, text: 'Beep boop') }

      it 'reformats' do
        is_expected.to eq 'Beep boop'
      end

      context 'with custom_emojify option' do
        let!(:emoji) { Fabricate(:custom_emoji, domain: remote_account.domain) }
        let(:status) { Fabricate(:status, account: remote_account, text: text) }

        subject { Formatter.instance.format(status, custom_emojify: true) }

        context 'with emoji at the start' do
          let(:text) { '<p>:coolcat: Beep boop<br />' }

          it 'converts shortcode to image tag' do
            is_expected.to match(/<p><img draggable="false" class="emojione" alt=":coolcat:"/)
          end
        end

        context 'with emoji in the middle' do
          let(:text) { '<p>Beep :coolcat: boop</p>' }

          it 'converts shortcode to image tag' do
            is_expected.to match(/Beep <img draggable="false" class="emojione" alt=":coolcat:"/)
          end
        end

        context 'with concatenated emoji' do
          let(:text) { '<p>:coolcat::coolcat:</p>' }

          it 'does not touch the shortcodes' do
            is_expected.to match(/<p>:coolcat::coolcat:<\/p>/)
          end
        end

        context 'with emoji at the end' do
          let(:text) { '<p>Beep boop<br />:coolcat:</p>' }

          it 'converts shortcode to image tag' do
            is_expected.to match(/<br><img draggable="false" class="emojione" alt=":coolcat:"/)
          end
        end
      end
    end
  end

  describe '#reformat' do
    subject { Formatter.instance.reformat(text) }

    context 'contains plain text' do
      let(:text) { 'Beep boop' }

      it 'contains plain text' do
        is_expected.to include 'Beep boop'
      end
    end

    context 'contains scripts' do
      let(:text) { '<script>alert("Hello")</script>' }

      it 'strips scripts' do
        is_expected.to_not include '<script>alert("Hello")</script>'
      end
    end

    context 'contains malicious classes' do
      let(:text) { '<span class="mention	status__content__spoiler-link">Show more</span>' }

      it 'strips malicious classes' do
        is_expected.to_not include 'status__content__spoiler-link'
      end
    end
  end

  describe '#plaintext' do
    subject { Formatter.instance.plaintext(status) }

    context 'with local status' do
      let(:status)  { Fabricate(:status, text: '<p>a text by a nerd who uses an HTML tag in text</p>', uri: nil) }

      it 'returns raw text' do
        is_expected.to eq '<p>a text by a nerd who uses an HTML tag in text</p>'
      end
    end

    context 'with remote status' do
      let(:status)  { Fabricate(:status, account: remote_account, text: '<script>alert("Hello")</script>') }

      it 'returns tag-stripped text' do
        is_expected.to eq ''
      end
    end
  end

  describe '#simplified_format' do
    subject { Formatter.instance.simplified_format(account) }

    context 'with local status' do
      let(:account) { Fabricate(:account, domain: nil, note: text) }

      context 'contains linkable mentions for local accounts' do
        let(:text) { '@alice' }

        before { local_account }

        it 'links' do
          is_expected.to eq '<p><span class="h-card"><a href="https://cb6e6126.ngrok.io/@alice" class="u-url mention">@<span>alice</span></a></span></p>'
        end
      end

      context 'contains linkable mentions for remote accounts' do
        let(:text) { '@bob@remote.test' }

        before { remote_account }

        it 'links' do
          is_expected.to eq '<p><span class="h-card"><a href="https://remote.test/" class="u-url mention">@<span>bob</span></a></span></p>'
        end
      end

      context 'contains unlinkable mentions' do
        let(:text) { '@alice' }

        it 'returns raw mention texts' do
          is_expected.to eq '<p>@alice</p>'
        end
      end

      context 'with custom_emojify option' do
        let!(:emoji) { Fabricate(:custom_emoji) }

        before { account.note = text }
        subject { Formatter.instance.simplified_format(account, custom_emojify: true) }

        context 'with emoji at the start' do
          let(:text) { ':coolcat: Beep boop' }

          it 'converts shortcode to image tag' do
            is_expected.to match(/<p><img draggable="false" class="emojione" alt=":coolcat:"/)
          end
        end

        context 'with emoji in the middle' do
          let(:text) { 'Beep :coolcat: boop' }

          it 'converts shortcode to image tag' do
            is_expected.to match(/Beep <img draggable="false" class="emojione" alt=":coolcat:"/)
          end
        end

        context 'with concatenated emoji' do
          let(:text) { ':coolcat::coolcat:' }

          it 'does not touch the shortcodes' do
            is_expected.to match(/:coolcat::coolcat:/)
          end
        end

        context 'with emoji at the end' do
          let(:text) { 'Beep boop :coolcat:' }

          it 'converts shortcode to image tag' do
            is_expected.to match(/boop <img draggable="false" class="emojione" alt=":coolcat:"/)
          end
        end
      end

      include_examples 'encode and link URLs'
    end

    context 'with remote status' do
      let(:text) { '<script>alert("Hello")</script>' }
      let(:account) { Fabricate(:account, domain: 'remote', note: text) }

      it 'reformats' do
        is_expected.to_not include '<script>alert("Hello")</script>'
      end

      context 'with custom_emojify option' do
        let!(:emoji) { Fabricate(:custom_emoji, domain: remote_account.domain) }

        before { remote_account.note = text }

        subject { Formatter.instance.simplified_format(remote_account, custom_emojify: true) }

        context 'with emoji at the start' do
          let(:text) { '<p>:coolcat: Beep boop<br />' }

          it 'converts shortcode to image tag' do
            is_expected.to match(/<p><img draggable="false" class="emojione" alt=":coolcat:"/)
          end
        end

        context 'with emoji in the middle' do
          let(:text) { '<p>Beep :coolcat: boop</p>' }

          it 'converts shortcode to image tag' do
            is_expected.to match(/Beep <img draggable="false" class="emojione" alt=":coolcat:"/)
          end
        end

        context 'with concatenated emoji' do
          let(:text) { '<p>:coolcat::coolcat:</p>' }

          it 'does not touch the shortcodes' do
            is_expected.to match(/<p>:coolcat::coolcat:<\/p>/)
          end
        end

        context 'with emoji at the end' do
          let(:text) { '<p>Beep boop<br />:coolcat:</p>' }

          it 'converts shortcode to image tag' do
            is_expected.to match(/<br><img draggable="false" class="emojione" alt=":coolcat:"/)
          end
        end
      end
    end
  end

  describe '#sanitize' do
    let(:html) { '<script>alert("Hello")</script>' }

    subject { Formatter.instance.sanitize(html, Sanitize::Config::MASTODON_STRICT) }

    it 'sanitizes' do
      is_expected.to eq 'alert("Hello")'
    end
  end
end
