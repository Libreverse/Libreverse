# frozen_string_literal: true

# == Route Map
#
# Routes for application:
#                                                Prefix Verb   URI Pattern                                                                                          Controller#Action
#                                    rails_service_blob GET    /rails/active_storage/blobs/redirect/:signed_id/*filename(.:format)                                  active_storage/blobs/redirect#show
#                              rails_service_blob_proxy GET    /rails/active_storage/blobs/proxy/:signed_id/*filename(.:format)                                     active_storage/blobs/proxy#show
#                                                       GET    /rails/active_storage/blobs/:signed_id/*filename(.:format)                                           active_storage/blobs/redirect#show
#                             rails_blob_representation GET    /rails/active_storage/representations/redirect/:signed_blob_id/:variation_key/*filename(.:format)    active_storage/representations/redirect#show
#                       rails_blob_representation_proxy GET    /rails/active_storage/representations/proxy/:signed_blob_id/:variation_key/*filename(.:format)       active_storage/representations/proxy#show
#                                                       GET    /rails/active_storage/representations/:signed_blob_id/:variation_key/*filename(.:format)             active_storage/representations/redirect#show
#                                    rails_disk_service GET    /rails/active_storage/disk/:encoded_key/*filename(.:format)                                          active_storage/disk#show
#                             update_rails_disk_service PUT    /rails/active_storage/disk/:encoded_token(.:format)                                                  active_storage/disk#update
#                                  rails_direct_uploads POST   /rails/active_storage/direct_uploads(.:format)                                                       active_storage/direct_uploads#create
#                                           sidekiq_web        /admin/sidekiq                                                                                       Sidekiq::Web
#                                       comfy_admin_cms GET    /cms-admin(.:format)                                                                                 comfy/admin/cms/base#jump
#                    reorder_comfy_admin_cms_site_pages PUT    /cms-admin/sites/:site_id/pages/reorder(.:format)                                                    comfy/admin/cms/pages#reorder
#              form_fragments_comfy_admin_cms_site_page GET    /cms-admin/sites/:site_id/pages/:id/form_fragments(.:format)                                         comfy/admin/cms/pages#form_fragments
#             revert_comfy_admin_cms_site_page_revision PATCH  /cms-admin/sites/:site_id/pages/:page_id/revisions/:id/revert(.:format)                              comfy/admin/cms/revisions/page#revert
#                   comfy_admin_cms_site_page_revisions GET    /cms-admin/sites/:site_id/pages/:page_id/revisions(.:format)                                         comfy/admin/cms/revisions/page#index
#                    comfy_admin_cms_site_page_revision GET    /cms-admin/sites/:site_id/pages/:page_id/revisions/:id(.:format)                                     comfy/admin/cms/revisions/page#show
#               toggle_branch_comfy_admin_cms_site_page GET    /cms-admin/sites/:site_id/pages/:id/toggle_branch(.:format)                                          comfy/admin/cms/pages#toggle_branch
#  form_fragments_comfy_admin_cms_site_page_translation GET    /cms-admin/sites/:site_id/pages/:page_id/translations/:id/form_fragments(.:format)                   comfy/admin/cms/translations#form_fragments
# revert_comfy_admin_cms_site_page_translation_revision PATCH  /cms-admin/sites/:site_id/pages/:page_id/translations/:translation_id/revisions/:id/revert(.:format) comfy/admin/cms/revisions/translation#revert
#       comfy_admin_cms_site_page_translation_revisions GET    /cms-admin/sites/:site_id/pages/:page_id/translations/:translation_id/revisions(.:format)            comfy/admin/cms/revisions/translation#index
#        comfy_admin_cms_site_page_translation_revision GET    /cms-admin/sites/:site_id/pages/:page_id/translations/:translation_id/revisions/:id(.:format)        comfy/admin/cms/revisions/translation#show
#                comfy_admin_cms_site_page_translations POST   /cms-admin/sites/:site_id/pages/:page_id/translations(.:format)                                      comfy/admin/cms/translations#create
#             new_comfy_admin_cms_site_page_translation GET    /cms-admin/sites/:site_id/pages/:page_id/translations/new(.:format)                                  comfy/admin/cms/translations#new
#            edit_comfy_admin_cms_site_page_translation GET    /cms-admin/sites/:site_id/pages/:page_id/translations/:id/edit(.:format)                             comfy/admin/cms/translations#edit
#                 comfy_admin_cms_site_page_translation GET    /cms-admin/sites/:site_id/pages/:page_id/translations/:id(.:format)                                  comfy/admin/cms/translations#show
#                                                       PATCH  /cms-admin/sites/:site_id/pages/:page_id/translations/:id(.:format)                                  comfy/admin/cms/translations#update
#                                                       PUT    /cms-admin/sites/:site_id/pages/:page_id/translations/:id(.:format)                                  comfy/admin/cms/translations#update
#                                                       DELETE /cms-admin/sites/:site_id/pages/:page_id/translations/:id(.:format)                                  comfy/admin/cms/translations#destroy
#                            comfy_admin_cms_site_pages GET    /cms-admin/sites/:site_id/pages(.:format)                                                            comfy/admin/cms/pages#index
#                                                       POST   /cms-admin/sites/:site_id/pages(.:format)                                                            comfy/admin/cms/pages#create
#                         new_comfy_admin_cms_site_page GET    /cms-admin/sites/:site_id/pages/new(.:format)                                                        comfy/admin/cms/pages#new
#                        edit_comfy_admin_cms_site_page GET    /cms-admin/sites/:site_id/pages/:id/edit(.:format)                                                   comfy/admin/cms/pages#edit
#                             comfy_admin_cms_site_page PATCH  /cms-admin/sites/:site_id/pages/:id(.:format)                                                        comfy/admin/cms/pages#update
#                                                       PUT    /cms-admin/sites/:site_id/pages/:id(.:format)                                                        comfy/admin/cms/pages#update
#                                                       DELETE /cms-admin/sites/:site_id/pages/:id(.:format)                                                        comfy/admin/cms/pages#destroy
#                    reorder_comfy_admin_cms_site_files PUT    /cms-admin/sites/:site_id/files/reorder(.:format)                                                    comfy/admin/cms/files#reorder
#                            comfy_admin_cms_site_files GET    /cms-admin/sites/:site_id/files(.:format)                                                            comfy/admin/cms/files#index
#                                                       POST   /cms-admin/sites/:site_id/files(.:format)                                                            comfy/admin/cms/files#create
#                         new_comfy_admin_cms_site_file GET    /cms-admin/sites/:site_id/files/new(.:format)                                                        comfy/admin/cms/files#new
#                        edit_comfy_admin_cms_site_file GET    /cms-admin/sites/:site_id/files/:id/edit(.:format)                                                   comfy/admin/cms/files#edit
#                             comfy_admin_cms_site_file PATCH  /cms-admin/sites/:site_id/files/:id(.:format)                                                        comfy/admin/cms/files#update
#                                                       PUT    /cms-admin/sites/:site_id/files/:id(.:format)                                                        comfy/admin/cms/files#update
#                                                       DELETE /cms-admin/sites/:site_id/files/:id(.:format)                                                        comfy/admin/cms/files#destroy
#                  reorder_comfy_admin_cms_site_layouts PUT    /cms-admin/sites/:site_id/layouts/reorder(.:format)                                                  comfy/admin/cms/layouts#reorder
#           revert_comfy_admin_cms_site_layout_revision PATCH  /cms-admin/sites/:site_id/layouts/:layout_id/revisions/:id/revert(.:format)                          comfy/admin/cms/revisions/layout#revert
#                 comfy_admin_cms_site_layout_revisions GET    /cms-admin/sites/:site_id/layouts/:layout_id/revisions(.:format)                                     comfy/admin/cms/revisions/layout#index
#                  comfy_admin_cms_site_layout_revision GET    /cms-admin/sites/:site_id/layouts/:layout_id/revisions/:id(.:format)                                 comfy/admin/cms/revisions/layout#show
#                          comfy_admin_cms_site_layouts GET    /cms-admin/sites/:site_id/layouts(.:format)                                                          comfy/admin/cms/layouts#index
#                                                       POST   /cms-admin/sites/:site_id/layouts(.:format)                                                          comfy/admin/cms/layouts#create
#                       new_comfy_admin_cms_site_layout GET    /cms-admin/sites/:site_id/layouts/new(.:format)                                                      comfy/admin/cms/layouts#new
#                      edit_comfy_admin_cms_site_layout GET    /cms-admin/sites/:site_id/layouts/:id/edit(.:format)                                                 comfy/admin/cms/layouts#edit
#                           comfy_admin_cms_site_layout PATCH  /cms-admin/sites/:site_id/layouts/:id(.:format)                                                      comfy/admin/cms/layouts#update
#                                                       PUT    /cms-admin/sites/:site_id/layouts/:id(.:format)                                                      comfy/admin/cms/layouts#update
#                                                       DELETE /cms-admin/sites/:site_id/layouts/:id(.:format)                                                      comfy/admin/cms/layouts#destroy
#                 reorder_comfy_admin_cms_site_snippets PUT    /cms-admin/sites/:site_id/snippets/reorder(.:format)                                                 comfy/admin/cms/snippets#reorder
#          revert_comfy_admin_cms_site_snippet_revision PATCH  /cms-admin/sites/:site_id/snippets/:snippet_id/revisions/:id/revert(.:format)                        comfy/admin/cms/revisions/snippet#revert
#                comfy_admin_cms_site_snippet_revisions GET    /cms-admin/sites/:site_id/snippets/:snippet_id/revisions(.:format)                                   comfy/admin/cms/revisions/snippet#index
#                 comfy_admin_cms_site_snippet_revision GET    /cms-admin/sites/:site_id/snippets/:snippet_id/revisions/:id(.:format)                               comfy/admin/cms/revisions/snippet#show
#                         comfy_admin_cms_site_snippets GET    /cms-admin/sites/:site_id/snippets(.:format)                                                         comfy/admin/cms/snippets#index
#                                                       POST   /cms-admin/sites/:site_id/snippets(.:format)                                                         comfy/admin/cms/snippets#create
#                      new_comfy_admin_cms_site_snippet GET    /cms-admin/sites/:site_id/snippets/new(.:format)                                                     comfy/admin/cms/snippets#new
#                     edit_comfy_admin_cms_site_snippet GET    /cms-admin/sites/:site_id/snippets/:id/edit(.:format)                                                comfy/admin/cms/snippets#edit
#                          comfy_admin_cms_site_snippet PATCH  /cms-admin/sites/:site_id/snippets/:id(.:format)                                                     comfy/admin/cms/snippets#update
#                                                       PUT    /cms-admin/sites/:site_id/snippets/:id(.:format)                                                     comfy/admin/cms/snippets#update
#                                                       DELETE /cms-admin/sites/:site_id/snippets/:id(.:format)                                                     comfy/admin/cms/snippets#destroy
#                       comfy_admin_cms_site_categories GET    /cms-admin/sites/:site_id/categories(.:format)                                                       comfy/admin/cms/categories#index
#                                                       POST   /cms-admin/sites/:site_id/categories(.:format)                                                       comfy/admin/cms/categories#create
#                     new_comfy_admin_cms_site_category GET    /cms-admin/sites/:site_id/categories/new(.:format)                                                   comfy/admin/cms/categories#new
#                    edit_comfy_admin_cms_site_category GET    /cms-admin/sites/:site_id/categories/:id/edit(.:format)                                              comfy/admin/cms/categories#edit
#                         comfy_admin_cms_site_category PATCH  /cms-admin/sites/:site_id/categories/:id(.:format)                                                   comfy/admin/cms/categories#update
#                                                       PUT    /cms-admin/sites/:site_id/categories/:id(.:format)                                                   comfy/admin/cms/categories#update
#                                                       DELETE /cms-admin/sites/:site_id/categories/:id(.:format)                                                   comfy/admin/cms/categories#destroy
#                                 comfy_admin_cms_sites GET    /cms-admin/sites(.:format)                                                                           comfy/admin/cms/sites#index
#                                                       POST   /cms-admin/sites(.:format)                                                                           comfy/admin/cms/sites#create
#                              new_comfy_admin_cms_site GET    /cms-admin/sites/new(.:format)                                                                       comfy/admin/cms/sites#new
#                             edit_comfy_admin_cms_site GET    /cms-admin/sites/:id/edit(.:format)                                                                  comfy/admin/cms/sites#edit
#                                  comfy_admin_cms_site PATCH  /cms-admin/sites/:id(.:format)                                                                       comfy/admin/cms/sites#update
#                                                       PUT    /cms-admin/sites/:id(.:format)                                                                       comfy/admin/cms/sites#update
#                                                       DELETE /cms-admin/sites/:id(.:format)                                                                       comfy/admin/cms/sites#destroy
#                                  comfy_cms_render_css GET    /blog/cms-css/:site_id/:identifier(/:cache_buster)(.:format)                                         comfy/cms/assets#render_css
#                                   comfy_cms_render_js GET    /blog/cms-js/:site_id/:identifier(/:cache_buster)(.:format)                                          comfy/cms/assets#render_js
#                                 comfy_cms_render_page GET    /blog(/*cms_path)(.:format)                                                                          comfy/cms/content#show
#                                               graphql POST   /graphql(.:format)                                                                                   graphql#execute
#                                      search_new_index GET    /search_new(.:format)                                                                                search_new#index
#                                                       GET    /search_new/index(.:format)                                                                          search_new#index
#                                                search GET    /search(.:format)                                                                                    search#index
#                                                  root GET    /                                                                                                    homepage#index
#                                                 terms GET    /terms(.:format)                                                                                     terms#index
#                                              settings GET    /settings(.:format)                                                                                  settings#index
#                                    rails_health_check GET    /up(.:format)                                                                                        rails/health#show
#                                                              /cable                                                                                               #<ActionCable::Server::Base:0x14b458 @config=#<ActionCable::Server::Configuration:0x14b468 @log_tags=[:action_cable], @connection_class=#<Proc:0x14b488 /Users/george/.gem/truffleruby/3.3.7/gems/actioncable-8.1.1/lib/action_cable/engine.rb:55 (lambda)>, @worker_pool_size=4, @disable_request_forgery_protection=false, @allow_same_origin_as_host=true, @filter_parameters=[:passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :name, :username, :email, :address, :phone, :birth, :gender, :national, :card, :account, :iban, :bank, :tax, :income, :health, :medical, :insurance, :csrf, :xsrf, :session, :cookie, :auth, :social, :verification, :answer, :key, :secret_question], @health_check_application=#<Proc:0x14b4a8 /Users/george/.gem/truffleruby/3.3.7/gems/actioncable-8.1.1/lib/action_cable/engine.rb:31 (lambda)>, @logger=#<ActiveSupport::Logger:0x10d878 @level=3, @progname=nil, @default_formatter=#<Logger::Formatter:0x14b4b8 @datetime_format=nil>, @formatter=#<ActiveSupport::Logger::SimpleFormatter:0x14b4d8 @datetime_format=nil>, @logdev=#<Logger::LogDevice:0x14b4f8 @shift_period_suffix=nil, @shift_size=nil, @shift_age=nil, @filename=nil, @dev=#<IO:fd 1>, @binmode=false, @reraise_write_errors=[], @skip_header=false, @mon_mutex=#<Mutex:0x14b508>, @mon_mutex_owner_object=#<Logger::LogDevice:0x14b4f8 ...>>, @level_override={}, @local_level_key=:logger_thread_safe_level_1103992>, @cable={"adapter"=>"redis", "url"=>"redis://127.0.0.1:6379/1", "channel_prefix"=>"libreverse_development"}, @mount_path="/cable", @precompile_assets=true, @url="wss://localhost:3000/cable", @allowed_request_origins=["https://localhost:3000", "https://127.0.0.1:3000", "https://[::1]:3000", "https://localhost:5173", "https://127.0.0.1:5173", "https://[::1]:5173", "file://"]>, @mutex=#<Monitor:0x14b588 @mon_mutex=#<Mutex:0x14b598>, @mon_mutex_owner_object=#<Monitor:0x14b588 ...>>, @pubsub=nil, @worker_pool=nil, @event_loop=nil, @remote_connections=nil>
#                                        action_mailbox        /rails/action_mailbox                                                                                ActionMailbox::Engine
#                                       federated_login GET    /federated-login(.:format)                                                                           federated_login#new
#                                                       POST   /federated-login(.:format)                                                                           federated_login#create
#                               auth_federated_callback GET    /auth/federated/callback(.:format)                                                                   federated_login#callback
#                                          auth_failure GET    /auth/failure(.:format)                                                                              federated_login#failure
#                                            api_xmlrpc POST   /api/xmlrpc(.:format)                                                                                api/xmlrpc#endpoint
#                                                   api GET    /api/json/:method(.:format)                                                                          api/json#endpoint
#                                                       POST   /api/json/:method(.:format)                                                                          api/json#endpoint
#                                              api_json POST   /api/json(.:format)                                                                                  api/json#endpoint
#                                             dashboard GET    /dashboard(.:format)                                                                                 dashboard#index
#                                    display_experience GET    /experiences/:id/display(.:format)                                                                   experiences#display
#                           electron_sandbox_experience GET    /experiences/:id/electron_sandbox(.:format)                                                          experiences#electron_sandbox
#                                           experiences GET    /experiences(.:format)                                                                               experiences#index
#                                                       POST   /experiences(.:format)                                                                               experiences#create
#                                        new_experience GET    /experiences/new(.:format)                                                                           experiences#new
#                                       edit_experience GET    /experiences/:id/edit(.:format)                                                                      experiences#edit
#                                            experience GET    /experiences/:id(.:format)                                                                           experiences#show
#                                                       PATCH  /experiences/:id(.:format)                                                                           experiences#update
#                                                       PUT    /experiences/:id(.:format)                                                                           experiences#update
#                                                       DELETE /experiences/:id(.:format)                                                                           experiences#destroy
#                                        account_export GET    /account/export(.:format)                                                                            account_actions#export
#                                               sidebar GET    /sidebar(.:format)                                                                                   layouts#sidebar
#                                        admin_comments GET    /admin/comments(.:format)                                                                            admin/comments#index
#                                   admin_indexing_runs GET    /admin/indexing_runs(.:format)                                                                       admin/indexing_runs#index
#                                    admin_indexing_run GET    /admin/indexing_runs/:id(.:format)                                                                   admin/indexing_runs#show
#                                     run_admin_indexer POST   /admin/indexers/:id/run(.:format)                                                                    admin/indexers#run
#                                        admin_indexers GET    /admin/indexers(.:format)                                                                            admin/indexers#index
#                                         admin_indexer GET    /admin/indexers/:id(.:format)                                                                        admin/indexers#show
#                                 admin_dashboard_index GET    /admin/dashboard(.:format)                                                                           admin/dashboard#index
#                                            admin_root GET    /admin(.:format)                                                                                     admin/dashboard#index
#                                enable_admin_profiling POST   /admin/profiling/enable(.:format)                                                                    admin/profilings#enable
#                               disable_admin_profiling POST   /admin/profiling/disable(.:format)                                                                   admin/profilings#disable
#                         force_disable_admin_profiling POST   /admin/profiling/force_disable(.:format)                                                             admin/profilings#force_disable
#                                 admin_active_hashcash        /admin/hashcash                                                                                      ActiveHashcash::Engine
#                                     admin_experiences GET    /admin/experiences(.:format)                                                                         admin/experiences#index
#                               admin_instance_settings GET    /admin/instance_settings(.:format)                                                                   admin/instance_settings#index
#                                                       POST   /admin/instance_settings(.:format)                                                                   admin/instance_settings#create
#                            new_admin_instance_setting GET    /admin/instance_settings/new(.:format)                                                               admin/instance_settings#new
#                           edit_admin_instance_setting GET    /admin/instance_settings/:id/edit(.:format)                                                          admin/instance_settings#edit
#                                admin_instance_setting GET    /admin/instance_settings/:id(.:format)                                                               admin/instance_settings#show
#                                                       PATCH  /admin/instance_settings/:id(.:format)                                                               admin/instance_settings#update
#                                                       PUT    /admin/instance_settings/:id(.:format)                                                               admin/instance_settings#update
#                                                       DELETE /admin/instance_settings/:id(.:format)                                                               admin/instance_settings#destroy
#                                      admin_federation GET    /admin/federation(.:format)                                                                          admin/federation#index
#                admin_federation_federated_experiences GET    /admin/federation/federated_experiences(.:format)                                                    admin/federation#federated_experiences
#                               admin_active_storage_db        /admin/active_storage_db                                                                             ActiveStorageDB::Engine
#                                                       GET    /.well-known/security.txt                                                                            well_known#security_txt
#                                                       GET    /.well-known/privacy.txt                                                                             well_known#privacy_txt
#                                                       GET    /.well-known/libreverse                                                                              federation#libreverse_discovery
#                                                       GET    /robots.txt                                                                                          robots#show
#                                                       GET    /sitemap.xml                                                                                         sitemap#show
#                           api_activitypub_experiences GET    /api/activitypub/experiences(.:format)                                                               federation#experiences_collection
#                                api_activitypub_search GET    /api/activitypub/search(.:format)                                                                    federation#search
#                              api_activitypub_announce POST   /api/activitypub/announce(.:format)                                                                  federation#announce
#                                                       POST   /api/activitypub/announce(.:format)                                                                  federation#announce
#                                        consent_screen GET    /consent/screen(.:format)                                                                            consent#screen
#                                            audits1984        /console                                                                                             Audits1984::Engine
#                                               privacy GET    /privacy(.:format)                                                                                   policies#privacy
#                                         cookie_policy GET    /cookies(.:format)                                                                                   policies#cookies
#                                                   map GET    /map(.:format)                                                                                       map#index
#                                                    lm GET    /lm(.:format)                                                                                        lm#index
#                                              thredded        /forum                                                                                               Thredded::Engine
#                                             federails        /                                                                                                    Federails::Engine
#                      turbo_recede_historical_location GET    /recede_historical_location(.:format)                                                                turbo/native/navigation#recede
#                      turbo_resume_historical_location GET    /resume_historical_location(.:format)                                                                turbo/native/navigation#resume
#                     turbo_refresh_historical_location GET    /refresh_historical_location(.:format)                                                               turbo/native/navigation#refresh
#                         rails_postmark_inbound_emails POST   /rails/action_mailbox/postmark/inbound_emails(.:format)                                              action_mailbox/ingresses/postmark/inbound_emails#create
#                            rails_relay_inbound_emails POST   /rails/action_mailbox/relay/inbound_emails(.:format)                                                 action_mailbox/ingresses/relay/inbound_emails#create
#                         rails_sendgrid_inbound_emails POST   /rails/action_mailbox/sendgrid/inbound_emails(.:format)                                              action_mailbox/ingresses/sendgrid/inbound_emails#create
#                   rails_mandrill_inbound_health_check GET    /rails/action_mailbox/mandrill/inbound_emails(.:format)                                              action_mailbox/ingresses/mandrill/inbound_emails#health_check
#                         rails_mandrill_inbound_emails POST   /rails/action_mailbox/mandrill/inbound_emails(.:format)                                              action_mailbox/ingresses/mandrill/inbound_emails#create
#                          rails_mailgun_inbound_emails POST   /rails/action_mailbox/mailgun/inbound_emails/mime(.:format)                                          action_mailbox/ingresses/mailgun/inbound_emails#create
#                        rails_conductor_inbound_emails GET    /rails/conductor/action_mailbox/inbound_emails(.:format)                                             rails/conductor/action_mailbox/inbound_emails#index
#                                                       POST   /rails/conductor/action_mailbox/inbound_emails(.:format)                                             rails/conductor/action_mailbox/inbound_emails#create
#                     new_rails_conductor_inbound_email GET    /rails/conductor/action_mailbox/inbound_emails/new(.:format)                                         rails/conductor/action_mailbox/inbound_emails#new
#                         rails_conductor_inbound_email GET    /rails/conductor/action_mailbox/inbound_emails/:id(.:format)                                         rails/conductor/action_mailbox/inbound_emails#show
#              new_rails_conductor_inbound_email_source GET    /rails/conductor/action_mailbox/inbound_emails/sources/new(.:format)                                 rails/conductor/action_mailbox/inbound_emails/sources#new
#                 rails_conductor_inbound_email_sources POST   /rails/conductor/action_mailbox/inbound_emails/sources(.:format)                                     rails/conductor/action_mailbox/inbound_emails/sources#create
#                 rails_conductor_inbound_email_reroute POST   /rails/conductor/action_mailbox/:inbound_email_id/reroute(.:format)                                  rails/conductor/action_mailbox/reroutes#create
#              rails_conductor_inbound_email_incinerate POST   /rails/conductor/action_mailbox/:inbound_email_id/incinerate(.:format)                               rails/conductor/action_mailbox/incinerates#create
#                                               consent GET    /consent(.:format)                                                                                   consents#show
#                                        consent_accept POST   /consent/accept(.:format)                                                                            consents#accept
#                                       consent_decline POST   /consent/decline(.:format)                                                                           consents#decline
#
# Routes for ActionMailbox::Engine:
# No routes defined.
#
# Routes for ActiveHashcash::Engine:
#    Prefix Verb URI Pattern              Controller#Action
#     asset GET  /assets/:id(.:format)    active_hashcash/assets#show
#    stamps GET  /stamps(.:format)        active_hashcash/stamps#index
#     stamp GET  /stamps/:id(.:format)    active_hashcash/stamps#show
# addresses GET  /addresses(.:format)     active_hashcash/addresses#index
#   address GET  /addresses/:id(.:format) active_hashcash/addresses#show
#      root GET  /                        active_hashcash/stamps#index
#
# Routes for ActiveStorageDB::Engine:
#         Prefix Verb URI Pattern                             Controller#Action
#        service GET  /files/:encoded_key/*filename(.:format) active_storage_db/files#show
# update_service PUT  /files/:encoded_token(.:format)         active_storage_db/files#update
#
# Routes for Audits1984::Engine:
#            Prefix Verb  URI Pattern                                Controller#Action
#    session_audits POST  /sessions/:session_id/audits(.:format)     audits1984/audits#create
#     session_audit PATCH /sessions/:session_id/audits/:id(.:format) audits1984/audits#update
#                   PUT   /sessions/:session_id/audits/:id(.:format) audits1984/audits#update
#          sessions GET   /sessions(.:format)                        audits1984/sessions#index
#           session GET   /sessions/:id(.:format)                    audits1984/sessions#show
# filtered_sessions PATCH /filtered_sessions(.:format)               audits1984/filtered_sessions#update
#                   PUT   /filtered_sessions(.:format)               audits1984/filtered_sessions#update
#              root GET   /                                          audits1984/sessions#index
#
# Routes for Thredded::Engine:
#                                 Prefix Verb     URI Pattern                                                          Controller#Action
#                          theme_preview GET      /theme-preview(.:format)                                             thredded/theme_previews#show
#           mark_all_private_topics_read PATCH    /private-topics/read_state(.:format)                                 thredded/read_states#update
#                                        PUT      /private-topics/read_state(.:format)                                 thredded/read_states#update
#              preview_new_private_topic POST     /private-topics/new/preview(.:format)                                thredded/private_topic_previews#preview
#                      new_private_topic GET      /private-topics/new(.:format)                                        thredded/private_topics#new
#                          private_topic GET      /private-topics/:id(/page-:page)(.:format)                           thredded/private_topics#show {:page=>/[1-9]\d*/}
# preview_new_private_topic_private_post POST     /private-topics/:private_topic_id/new/preview(.:format)              thredded/private_post_previews#preview
#     private_topic_private_post_preview PATCH    /private-topics/:private_topic_id/:private_post_id/preview(.:format) thredded/private_post_previews#update
#                                        PUT      /private-topics/:private_topic_id/:private_post_id/preview(.:format) thredded/private_post_previews#update
#       quote_private_topic_private_post GET      /private-topics/:private_topic_id/:id/quote(.:format)                thredded/private_posts#quote
#            private_topic_private_posts POST     /private-topics/:private_topic_id(.:format)                          thredded/private_posts#create
#         new_private_topic_private_post GET      /private-topics/:private_topic_id/new(.:format)                      thredded/private_posts#new
#        edit_private_topic_private_post GET      /private-topics/:private_topic_id/:id/edit(.:format)                 thredded/private_posts#edit
#             private_topic_private_post PATCH    /private-topics/:private_topic_id/:id(.:format)                      thredded/private_posts#update
#                                        PUT      /private-topics/:private_topic_id/:id(.:format)                      thredded/private_posts#update
#                                        DELETE   /private-topics/:private_topic_id/:id(.:format)                      thredded/private_posts#destroy
#                         private_topics GET      /private-topics(.:format)                                            thredded/private_topics#index
#                                        POST     /private-topics(.:format)                                            thredded/private_topics#create
#                     edit_private_topic GET      /private-topics/:id/edit(.:format)                                   thredded/private_topics#edit
#                                        PATCH    /private-topics/:id(.:format)                                        thredded/private_topics#update
#                                        PUT      /private-topics/:id(.:format)                                        thredded/private_topics#update
#                                        DELETE   /private-topics/:id(.:format)                                        thredded/private_topics#destroy
#                 private_post_permalink GET      /private-posts/:id(.:format)                                         thredded/private_post_permalinks#show {:id=>/[1-9]\d*/}
#                         post_permalink GET      /posts/:id(.:format)                                                 thredded/post_permalinks#show {:id=>/[1-9]\d*/}
#                     autocomplete_users GET      /autocomplete-users(.:format)                                        thredded/autocomplete_users#index
#                   messageboards_search GET      /                                                                    thredded/topics#search
#                    messageboard_search GET      /:messageboard_id(.:format)                                          thredded/topics#search
#                    messageboard_groups POST     /admin/messageboard_groups(.:format)                                 thredded/messageboard_groups#create
#                 new_messageboard_group GET      /admin/messageboard_groups/new(.:format)                             thredded/messageboard_groups#new
#                     pending_moderation GET      /admin/moderation(/page-:page)(.:format)                             thredded/moderation#pending {:page=>/[1-9]\d*/}
#                     moderation_history GET      /admin/moderation/history(/page-:page)(.:format)                     thredded/moderation#history {:page=>/[1-9]\d*/}
#                       users_moderation GET      /admin/moderation/users(/page-:page)(.:format)                       thredded/moderation#users {:page=>/[1-9]\d*/}
#                        user_moderation GET      /admin/moderation/users/:id(/page-:page)(.:format)                   thredded/moderation#user {:page=>/[1-9]\d*/}
#                    moderation_activity GET      /admin/moderation/activity(/page-:page)(.:format)                    thredded/moderation#activity {:page=>/[1-9]\d*/}
#                          moderate_post POST     /admin/moderation(.:format)                                          thredded/moderation#moderate_post
#                          moderate_user POST     /admin/moderation/user/:id(.:format)                                 thredded/moderation#moderate_user
#                          unread_topics GET      /unread(.:format)                                                    thredded/topics#unread
#                edit_global_preferences GET      /preferences/edit(.:format)                                          thredded/preferences#edit
#                     global_preferences PATCH    /preferences(.:format)                                               thredded/preferences#update
#                                        PUT      /preferences(.:format)                                               thredded/preferences#update
#                       new_messageboard GET      /messageboards/new(.:format)                                         thredded/messageboards#new
#                show_messageboard_group GET      /messageboard-groups/:id(.:format)                                   thredded/messageboard_groups#show
#                      edit_messageboard GET      /messageboards/:id/edit(.:format)                                    thredded/messageboards#edit
#                           messageboard PATCH    /messageboards/:id(.:format)                                         thredded/messageboards#update
#                                        PUT      /messageboards/:id(.:format)                                         thredded/messageboards#update
#                                        DELETE   /messageboards/:id(.:format)                                         thredded/messageboards#destroy
#          edit_messageboard_preferences GET      /:messageboard_id/preferences/edit(.:format)                         thredded/preferences#edit
#               messageboard_preferences PATCH    /:messageboard_id/preferences(.:format)                              thredded/preferences#update
#                                        PUT      /:messageboard_id/preferences(.:format)                              thredded/preferences#update
#         preview_new_messageboard_topic POST     /:messageboard_id/topics/new/preview(.:format)                       thredded/topic_previews#preview
#                 new_messageboard_topic GET      /:messageboard_id/topics/new(.:format)                               thredded/topics#new
#                    messageboard_topics GET      /:messageboard_id(/page-:page)(.:format)                             thredded/topics#index {:page=>/[1-9]\d*/}
#         categories_messageboard_topics GET      /:messageboard_id/category/:category_id(.:format)                    thredded/topics#category
#             unread_messageboard_topics GET      /:messageboard_id/unread(.:format)                                   thredded/topics#unread
#                     messageboard_topic GET      /:messageboard_id/:id(/page-:page)(.:format)                         thredded/topics#show {:page=>/[1-9]\d*/}
#              follow_messageboard_topic POST|GET /:messageboard_id/:id/follow(.:format)                               thredded/topics#follow
#            unfollow_messageboard_topic POST|GET /:messageboard_id/:id/unfollow(.:format)                             thredded/topics#unfollow
#    preview_new_messageboard_topic_post POST     /:messageboard_id/:topic_id/new/preview(.:format)                    thredded/post_previews#preview
#        messageboard_topic_post_preview PATCH    /:messageboard_id/:topic_id/:post_id/preview(.:format)               thredded/post_previews#update
#                                        PUT      /:messageboard_id/:topic_id/:post_id/preview(.:format)               thredded/post_previews#update
#          quote_messageboard_topic_post GET      /:messageboard_id/:topic_id/:id/quote(.:format)                      thredded/posts#quote
#               messageboard_topic_posts POST     /:messageboard_id/:topic_id(.:format)                                thredded/posts#create
#            new_messageboard_topic_post GET      /:messageboard_id/:topic_id/new(.:format)                            thredded/posts#new
#           edit_messageboard_topic_post GET      /:messageboard_id/:topic_id/:id/edit(.:format)                       thredded/posts#edit
#                messageboard_topic_post PATCH    /:messageboard_id/:topic_id/:id(.:format)                            thredded/posts#update
#                                        PUT      /:messageboard_id/:topic_id/:id(.:format)                            thredded/posts#update
#                                        DELETE   /:messageboard_id/:topic_id/:id(.:format)                            thredded/posts#destroy
#                                        POST     /:messageboard_id(.:format)                                          thredded/topics#create
#                edit_messageboard_topic GET      /:messageboard_id/:id/edit(.:format)                                 thredded/topics#edit
#                                        PATCH    /:messageboard_id/:id(.:format)                                      thredded/topics#update
#                                        PUT      /:messageboard_id/:id(.:format)                                      thredded/topics#update
#                                        DELETE   /:messageboard_id/:id(.:format)                                      thredded/topics#destroy
#                          messageboards GET      /                                                                    thredded/messageboards#index
#                                        POST     /                                                                    thredded/messageboards#create
#                      mark_as_read_post POST     /action/posts/:id/mark_as_read(.:format)                             thredded/posts#mark_as_read
#                    mark_as_unread_post POST     /action/posts/:id/mark_as_unread(.:format)                           thredded/posts#mark_as_unread
#              mark_as_read_private_post POST     /action/private_posts/:id/mark_as_read(.:format)                     thredded/private_posts#mark_as_read
#            mark_as_unread_private_post POST     /action/private_posts/:id/mark_as_unread(.:format)                   thredded/private_posts#mark_as_unread
#                                   root GET      /                                                                    thredded/messageboards#index
#
# Routes for Federails::Engine:
#                   Prefix Verb   URI Pattern                                           Controller#Action
#                webfinger GET    /.well-known/webfinger(.:format)                      federails/server/web_finger#find
#                host_meta GET    /.well-known/host-meta(.:format)                      federails/server/web_finger#host_meta
#                node_info GET    /.well-known/nodeinfo(.:format)                       federails/server/nodeinfo#index
#           show_node_info GET    /nodeinfo/2.0(.:format)                               federails/server/nodeinfo#show
#   feed_client_activities GET    /app/activities/feed(.:format)                        federails/client/activities#feed
#        client_activities GET    /app/activities(.:format)                             federails/client/activities#index
#     lookup_client_actors GET    /app/actors/lookup(.:format)                          federails/client/actors#lookup
#  client_actor_activities GET    /app/actors/:actor_id/activities(.:format)            federails/client/activities#index
#            client_actors GET    /app/actors(.:format)                                 federails/client/actors#index
#             client_actor GET    /app/actors/:id(.:format)                             federails/client/actors#show
#              client_feed GET    /app/feed(.:format)                                   federails/client/activities#feed
# follow_client_followings POST   /app/followings/follow(.:format)                      federails/client/followings#follow
#  accept_client_following PUT    /app/followings/:id/accept(.:format)                  federails/client/followings#accept
#        client_followings POST   /app/followings(.:format)                             federails/client/followings#create
#     new_client_following GET    /app/followings/new(.:format)                         federails/client/followings#new
#         client_following DELETE /app/followings/:id(.:format)                         federails/client/followings#destroy
#   followers_server_actor GET    /federation/actors/:id/followers(.:format)            federails/server/actors#followers {:format=>:activitypub}
#   following_server_actor GET    /federation/actors/:id/following(.:format)            federails/server/actors#following {:format=>:activitypub}
#      server_actor_outbox GET    /federation/actors/:actor_id/outbox(.:format)         federails/server/activities#outbox {:format=>:activitypub}
#       server_actor_inbox POST   /federation/actors/:actor_id/inbox(.:format)          federails/server/activities#create {:format=>:activitypub}
#    server_actor_activity GET    /federation/actors/:actor_id/activities/:id(.:format) federails/server/activities#show {:format=>:activitypub}
#   server_actor_following GET    /federation/actors/:actor_id/followings/:id(.:format) federails/server/followings#show {:format=>:activitypub}
#             server_actor GET    /federation/actors/:id(.:format)                      federails/server/actors#show {:format=>:activitypub}
#         server_published GET    /federation/published/:publishable_type/:id(.:format) federails/server/published#show {:format=>:activitypub}

# shareable_constant_value: literal

require "sidekiq/web"
require "sidekiq/cron/web"

# Constraint to require admin authentication for Sidekiq Web UI
class SidekiqAdminConstraint
  def matches?(request)
    return false unless request.session[:account_id]

    # Use AccountSequel for fast admin check (consistent with mini_profiler.rb)
    AccountSequel.where(id: request.session[:account_id]).get(:admin) == true
  rescue StandardError
    false
  end
end

Rails.application.routes.draw do
  # Sidekiq Web UI (admin only)
  constraints SidekiqAdminConstraint.new do
    mount Sidekiq::Web => "/admin/sidekiq"
  end

  # CMS Admin routes (secured with Rodauth)
  comfy_route :cms_admin, path: "/cms-admin"

  # Blog CMS routes - mount under /blog only
  comfy_route :cms, path: "/blog"
  post "/graphql", to: "graphql#execute"
  resources :search_new, only: [ :index ]
  get "search_new/index"
  get "search" => "search#index"
  root "homepage#index"
  get "terms", to: "terms#index"
  get "settings", to: "settings#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Mount ActionCable for real-time features
  mount ActionCable.server => "/cable"

  # Mount Action Mailbox for email bot functionality
  mount ActionMailbox::Engine => "/rails/action_mailbox"

  # Authentication routes (/login, /create-account, etc.) are automatically handled by Rodauth
  # See app/misc/rodauth_app.rb and run `rails rodauth:routes` to view all available routes

  # Federated authentication routes
  get "/federated-login", to: "federated_login#new"
  post "/federated-login", to: "federated_login#create"
  get "/auth/federated/callback", to: "federated_login#callback"
  get "/auth/failure", to: "federated_login#failure"

  # XML-RPC API endpoint
  namespace :api do
    post "xmlrpc", to: "xmlrpc#endpoint"
    get "json/:method", to: "json#endpoint"
    post "json/:method", to: "json#endpoint"
    post "json", to: "json#endpoint" # For method specified in body
  end

  # Dashboard route - accessible to both authenticated users and guests
  get "dashboard", to: "dashboard#index"

  # Routes available only if authenticated via Rodauth (excluding guest accounts)
  constraints Rodauth::Rails.authenticate do
    resources :experiences do
      member do
        get "display"
        get "electron_sandbox"
      end
    end
  end

  # Account export placed outside Rodauth constraint; controller handles auth.
  get "account/export", to: "account_actions#export", as: :account_export

  # Layout partials
  get "sidebar", to: "layouts#sidebar"

  # ===== Admin Namespace =====
  namespace :admin do
    resources :comments, only: %i[index]
    resources :indexing_runs, only: %i[index show]
    resources :indexers, only: %i[index show] do
      member do
        post :run # Allow triggering indexer runs
      end
    end
    # Dashboard
    resources :dashboard, only: [ :index ]
    root to: "dashboard#index"

    # Admin-only production profiling controls
    resource :profiling, only: [] do
      post :enable
      post :disable
      post :force_disable
    end

    # ActiveHashcash monitoring dashboard - admin only
    mount ActiveHashcash::Engine, at: "hashcash"

    resources :experiences, only: [ :index ]

    # Instance settings management
    resources :instance_settings

    # Federation management
    get "federation", to: "federation#index"
    get "federation/federated_experiences", to: "federation#federated_experiences"

    # ActiveStorageDB utilities (optional admin utilities)
    mount ActiveStorageDB::Engine => "/active_storage_db"
  end

  get ".well-known/security.txt", to: "well_known#security_txt", format: false
  get ".well-known/privacy.txt", to: "well_known#privacy_txt", format: false
  get ".well-known/libreverse", to: "federation#libreverse_discovery", format: false
  get "robots.txt", to: "robots#show", format: false
  get "sitemap.xml", to: "sitemap#show", format: false

  # ActivityPub federation endpoints
  get "/api/activitypub/experiences", to: "federation#experiences_collection"
  get "/api/activitypub/search", to: "federation#search"
  post "/api/activitypub/announce", to: "federation#announce"
  post "/api/activitypub/announce", to: "federation#announce"

  # Consent routes using Turbo Streams
  get  "consent/screen", to: "consent#screen", as: :consent_screen

  # Mount audits1984 engine for auditing console sessions
  mount Audits1984::Engine => "/console"

  # Policies (Privacy & Cookies)
  get "privacy", to: "policies#privacy", as: :privacy
  get "cookies", to: "policies#cookies", as: :cookie_policy

  # Metaverse synthetic map
  get "map", to: "map#index"

  # LLM page
  get "lm", to: "lm#index"

  # Mount Thredded forum engine
  mount Thredded::Engine => "/forum"

  # Mount Federails engine at root for ActivityPub federation
  mount Federails::Engine => "/"
end
