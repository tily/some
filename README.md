# some - sumo clone for NIFTY Cloud

## 概要

[adamwiggins/sumo](http://github.com/adamwiggins/sumo) の NIFTY Cloud バージョンです。
NIFTY Cloud 上で手軽にサーバーを立ち上げることができます。

    $ some launch
    ---> Launch instance...       4acef29d (7.9s)
    ---> Acquire hostname...      XXX.XXX.XXX.XXX (79.2s)
    ---> Wait for ssh...          done (0.0s)
    
    Logging you in via ssh.  Type 'exit' or Ctrl-D to return to your local system.
    ------------------------------------------------------------------------------
    Enter passphrase for key '/home/tily/.some/keypair.pem':
    [root@localhost ~]#

要らなくなったらすぐに削除できます。

    $ some terminate XXX.XXX.XXX.XXX
    ---> Wait to stop...          done (16.2s)
    XXX.XXX.XXX.XXX scheduled for termination

一覧を取得して SSH ログインしたりも簡単にできます。

    $ some list
    XXX.XXX.XXX.XXX                                    21b61298     running
    YYY.YYY.YYY.YYY                                    923d7772     running
    ZZZ.ZZZ.ZZZ.ZZZ                                    dec83cd3     running
    $ some ssh 21b61298
    Enter passphrase for key '/home/tily/.some/keypair.pem':
    Last login: Fri Apr  5 16:24:02 2013 from AAA.AAA.AAA.AAA
    [root@localhost ~]#

## インストール・設定

下記コマンドでインストールできます。

    gem install some

インストールが終わったら ~/.sumo/config.yml に設定ファイルを作成しましょう。
最小限下記を書けば使えます。

    ---
    access_key: (ここにアクセスキーを書く)
    secret_key: (ここにシークレットキーを書く)

設定できる項目をフルで書くとこんな感じになります。

    ---
    access_key: (デフォルト値なし)
    secret_key: (デフォルト値なし)
    user: root (デフォルト値)
    password: password (デフォルト値)
    instance_size: mini (デフォルト値)
    ami: 26 (デフォルト値)
    availability_zone: west-11 (デフォルト値)
    cookbooks_url: (デフォルト値なし、次節参照)
    role: (デフォルト値なし、次節参照)

## Chef でサービスをインストールする

少し頑張れば vagrant みたいなこともできます。
まずはグローバルからアクセスできる場所に cookbooks.tgz を置きましょう。
例：http://some.ncss.nifty.com/cookbooks.tgz

次に設定ファイル (~/.sumo/config.yml) にロールを定義しておきます。

    cookbooks_url: http://some.ncss.nifty.com/cookbooks.tgz
    role:
      mysql: |
        {
          "run_list": [
            "recipe[mysql::server]"
          ],
          "mysql": {
            "server_root_password": "mysql",
            "server_debian_password": "mysql",
            "server_repl_password": "mysql"
          }
        }

ここまでやればコマンド一発でサーバー作成・Chef インストール・Chef 実行まで行えます。

    $ some launch mysql
    ---> Launch instance...       d7f764b7 (7.6s)
    ---> Acquire hostname...      175.184.23.139 (89.4s)
    ---> Wait for ssh...          done (0.0s)
    ---> Bootstrap chef...        done (42.8s)
    ---> Setup mysql...           done (195.0s)

なお、上記を個別に実施することも可能です。

    $ some launch
    ---> Launch instance...       923d7772 (8.0s)
    ---> Acquire hostname...      XXX.XXX.XXX.XXX (90.5s)
    ---> Wait for ssh...          done (0.0s)
    
    $ some bootstrap 923d7772
    ---> Bootstrap chef...        done (46.0s)
    
    $ some role mysql 923d7772
    ---> Setup mysql...           done (184.6s)

## 詳細

 * サーバー作成の際に something という名前の SSH キーと FW を作成します
 * SSH キーは ~/.some/keypair.pem に保存されます

## ライセンス

[sumo](http://github.com/adamwiggins/sumo) と同じく MIT ライセンスで公開します。
