if status is-interactive
    set -g fish_greeting
    fastfetch
end

fish_add_path ~/.cargo/bin
fish_add_path ~/.local/bin

alias ytdlpmp3='mkdir -p ~/Musics; yt-dlp -x --audio-format mp3 --audio-quality 0 -o ~/Musics/"%(title)s.%(ext)s"'
alias ytdlpmp4='mkdir -p ~/Musics; yt-dlp -f "bestvideo+bestaudio" --merge-output-format mp4 -o ~/Musics/"%(title)s.%(ext)s"'

# ============================================================
# DEVos System Aliases & Helper (Arch Linux Only)
# ============================================================
if test -f /etc/arch-release
    function dev --description "DEVos system management and pacman helper"
        if test (count $argv) -eq 0
            echo -e "\033[1;36mDEVos System Helper\033[0m"
            echo "Usage: dev <command> [arguments...]"
            echo ""
            echo "Package Management (Pacman):"
            echo "  u, update        Update system (sudo pacman -Syu)"
            echo "  s, search        Search packages (pacman -Ss)"
            echo "  i, install       Install package (sudo pacman -S)"
            echo "  r, remove        Remove package + deps (sudo pacman -Rns)"
            echo "  q, query         Package information (pacman -Qi)"
            echo "  l, list          List package files (pacman -Ql)"
            echo "  c, clean         Clean package cache (sudo pacman -Sc)"
            echo "  orphans          Remove orphaned packages"
            echo ""
            echo "AUR Helper (paru / yay):"
            echo "  aur              Launch AUR helper"
            echo "  au               Update system & AUR packages"
            echo "  as               Search AUR & repo packages"
            echo "  ai               Install AUR package"
            echo ""
            echo "System Utilities:"
            echo "  sys, info        System summary (fastfetch)"
            echo "  top              Resource monitor (btop)"
            echo "  log              System logs (journalctl -xe)"
            echo "  services         Active systemd services"
            echo "  reboot           Reboot system"
            echo "  poweroff         Power off system"
            return 0
        end

        set -l cmd $argv[1]
        set -l args $argv[2..-1]

        switch $cmd
            case u update
                sudo pacman -Syu $args
            case s search
                pacman -Ss $args
            case i install
                sudo pacman -S $args
            case r remove
                sudo pacman -Rns $args
            case q query info
                pacman -Qi $args
            case l list
                pacman -Ql $args
            case c clean
                sudo pacman -Sc $args
            case orphans
                set -l orphan_pkgs (pacman -Qtdq)
                if test -n "$orphan_pkgs"
                    sudo pacman -Rns $orphan_pkgs $args
                else
                    echo "No orphaned packages found."
                end
            case aur
                if type -q paru
                    paru $args
                else if type -q yay
                    yay $args
                else
                    echo "Neither paru nor yay found."
                end
            case au
                if type -q paru
                    paru -Syu $args
                else if type -q yay
                    yay -Syu $args
                else
                    sudo pacman -Syu $args
                end
            case as
                if type -q paru
                    paru -Ss $args
                else if type -q yay
                    yay -Ss $args
                else
                    pacman -Ss $args
                end
            case ai
                if type -q paru
                    paru -S $args
                else if type -q yay
                    yay -S $args
                else
                    sudo pacman -S $args
                end
            case sys
                fastfetch $args
            case top
                btop $args
            case log
                journalctl -xe $args
            case services
                systemctl list-units --type=service $args
            case reboot
                systemctl reboot $args
            case poweroff
                systemctl poweroff $args
            case '*'
                echo "Unknown dev command: $cmd"
                echo "Run 'dev' without arguments for usage."
                return 1
        end
    end

    # Standalone hyphenated aliases
    alias dev-u='dev u'
    alias dev-s='dev s'
    alias dev-i='dev i'
    alias dev-r='dev r'
    alias dev-q='dev q'
    alias dev-l='dev l'
    alias dev-c='dev c'
    alias dev-orphans='dev orphans'
    alias dev-aur='dev aur'
    alias dev-au='dev au'
    alias dev-as='dev as'
    alias dev-ai='dev ai'
    alias dev-info='dev sys'
    alias dev-top='dev top'
    alias dev-log='dev log'
    alias dev-services='dev services'
end

