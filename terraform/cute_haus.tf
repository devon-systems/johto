locals {
  cute_haus_johto_ingress = {
    "appview.cute.haus"   = true
    "collabora.cute.haus" = false
    "cute.haus"           = true
    "id.cute.haus"        = true
    "immich.cute.haus"    = false
    "kuma.cute.haus"      = true
    "nextcloud.cute.haus" = false
    "paperless.cute.haus" = false
  }
}

resource "cloudflare_dns_record" "cute_haus_vaultwarden" {
  zone_id  = local.cute_haus_zone
  name     = "vault.cute.haus"
  type     = "A"
  content  = local.sinnoh_sunnyshore
  proxied  = true
  ttl      = 1
  tags     = []
  settings = {}
}

moved {
  from = cloudflare_dns_record.cute_haus_sinnoh_ingress["vault.cute.haus"]
  to   = cloudflare_dns_record.cute_haus_vaultwarden
}

resource "cloudflare_dns_record" "cute_haus_johto_ingress" {
  for_each = local.cute_haus_johto_ingress
  zone_id  = local.cute_haus_zone
  name     = each.key
  type     = "A"
  content  = local.olivine
  proxied  = each.value
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "cute_haus_ombi" {
  zone_id  = local.cute_haus_zone
  name     = "ombi.cute.haus"
  type     = "A"
  content  = local.olivine
  proxied  = true
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "cute_haus_plex" {
  zone_id  = local.cute_haus_zone
  name     = "plex.cute.haus"
  type     = "A"
  content  = local.olivine
  proxied  = false
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "cute_haus_www_cname" {
  zone_id  = local.cute_haus_zone
  name     = "www.cute.haus"
  type     = "CNAME"
  content  = "cute.haus"
  proxied  = false
  ttl      = 1
  tags     = []
  settings = { flatten_cname = false }
}

resource "cloudflare_dns_record" "cute_haus_atproto_txt" {
  zone_id  = local.cute_haus_zone
  name     = "_atproto.cute.haus"
  type     = "TXT"
  content  = "\"did=did:plc:rkos3laovknh53dwtdguu27n\""
  proxied  = false
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "cute_haus_apex_google_verify_txt" {
  zone_id  = local.cute_haus_zone
  name     = "cute.haus"
  type     = "TXT"
  content  = "\"google-site-verification=jN1nPjBAhwmZKG9jNUV631cEC_k7rZhlQxncMablr-E\""
  proxied  = false
  ttl      = 3600
  tags     = []
  settings = {}
}
