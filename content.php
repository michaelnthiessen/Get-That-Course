<?php
/**
 * This is the content template that is used to display 
 * content in loops.
 *
 * @package Alto
 */
?>

<article id="post-<?php the_ID(); ?>" <?php post_class(); ?>>

  <?php // Declare variables to help us determine context/type of post. ?>

  <?php 
    $thumbnail = has_post_thumbnail();
    $sticky    = is_sticky();
    $title     = get_the_title();
    $category  = get_the_category();
  ?>

  <?php // If the post is sticky. ?>

  <?php if ( $sticky ) : ?>

    <header class="entry-header <?php if ( $thumbnail ) { ?>has-thumbnail<?php } ?>">

      <?php if ( $thumbnail ) { ?> 
        <a href="<?php the_permalink(); ?>"><?php the_post_thumbnail( 'index-post' ); ?></a>
      <?php } ?>

      <?php if ( $category || $title ) { ?>

        <hgroup class="entry-title">

          <?php if ( $category ) { ?>
            <h5 class="category-title"><a href="<?php echo esc_url( get_category_link( $category[0]->term_id ) ); ?>"><?php echo esc_html( $category[0]->cat_name ); ?></a></h5>
          <?php } ?>

          <?php if ( $title ) { ?>
            <h1><a href="<?php the_permalink(); ?>" rel="bookmark"><?php the_title(); ?></a></h1>
          <?php } ?>

        </hgroup> <!-- end .entry-title -->

      <?php } ?>

    </header> <!-- end .entry-header.sticky -->

    <div class="entry-body">

      <div class="entry-content">

        <div class="entry-text">
          <?php
            the_content( __( '<span class="continue-reading">Continue Reading</span>', 'alto' ) );
            
            wp_link_pages( array(
              'before' => '<div class="page-links">' . __( 'Pages:', 'alto' ),
              'after'  => '</div>',
            ) );
          ?>
        </div> <!-- end .entry-text -->

      </div> <!-- end. entry-content -->

      <div class="entry-meta">
        <?php alto_posted_on(); ?>
      </div> <!-- end. entry-meta -->

    </div> <!-- end .entry-body -->

  <?php // If the post is not sticky. ?> 

  <?php else : ?>

    <div class="entry-body not-sticky <?php if ( ' ' != $thumbnail ) { echo "no-thumbnail"; } else { echo "has-thumbnail"; } ?>">
      
      <?php if ( is_home() ) { ?>
        <?php if ( $thumbnail ) { ?>  
          <div class="index-post-thumbnail">
            <a href="<?php the_permalink(); ?>"><?php the_post_thumbnail( 'index-post' ); ?></a>
          </div>
        <?php } ?>
      <?php } ?>

      <div class="entry-content">

        <?php // Move the header inline with the post content. ?>

        <header class="entry-header <?php if ( $thumbnail ) { ?>has-thumbnail<?php } ?>">

          <?php if ( !is_home() ) { ?>
            <?php if ( $thumbnail ) { ?>  
              <a href="<?php the_permalink(); ?>"><?php the_post_thumbnail( 'index-post' ); ?></a>
            <?php } ?>
          <?php } ?>

          <?php if ( $category || $title ) { ?>

            <hgroup class="entry-title">

              <?php if ( $category ) { ?>
                <h5 class="category-title"><a href="<?php echo esc_url( get_category_link( $category[0]->term_id ) ); ?>"><?php echo esc_html( $category[0]->cat_name ); ?></a></h5>
              <?php } ?>

              <?php if ( $title ) { ?>
                <h1><a href="<?php the_permalink(); ?>" rel="bookmark"><?php the_title(); ?></a></h1>
              <?php } ?>

            </hgroup> <!-- end .entry-title -->

          <?php } ?>

        </header> <!-- end .entry-header -->

        <div class="entry-text">
          <?php
            the_content( __( '<span class="continue-reading">Continue Reading</span>', 'alto' ) );
            
            wp_link_pages( array(
              'before' => '<div class="page-links">' . __( 'Pages:', 'alto' ),
              'after'  => '</div>',
            ) );
          ?>
        </div> <!-- end .entry-text -->

      </div> <!-- end. entry-content -->

      <div class="entry-meta <?php if ( is_home() && $thumbnail ) {?>has-thumbnail<?php } ?>">
        <?php alto_posted_on(); ?>
      </div> <!-- end. entry-meta -->

    </div> <!-- end .entry-body -->

  <?php endif; ?>

</article> <!-- end #post -->