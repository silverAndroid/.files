# Use Ubuntu as the base image
FROM ubuntu:22.04

# Set non-interactive frontend for package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    procps \
    curl \
    file \
    git \
    sudo \
    unzip \
    zsh \
    mosh \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create a non-root user and add it to the sudo group
RUN useradd -m -s /bin/bash -G sudo user
RUN echo "user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER user
WORKDIR /home/user

# Install Homebrew
RUN CI=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"
RUN echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/user/.zshrc && \
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/user/.bashrc


# Install packages with Homebrew
RUN brew install fzf zoxide "openjdk@21" bazelisk nvm stow

# Install Zinit
RUN bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"

# Install Oh My Posh
RUN curl -s https://ohmyposh.dev/install.sh | bash -s

# Copy the dotfiles
COPY --chown=user:user . /home/user/dotfiles

# Run stow
WORKDIR /home/user/dotfiles
RUN stow .
WORKDIR /home/user

# Set the default shell to zsh for the user
RUN sudo chsh -s /usr/bin/zsh user

# Set the default command to zsh
CMD ["/bin/zsh"]
